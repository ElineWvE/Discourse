# frozen_string_literal: true

module Chat
  # Service responsible for updating a message.
  #
  # @example
  #  Chat::UpdateMessage.call(message_id: 2, guardian: guardian, message: "A new message")
  #
  class UpdateMessage
    include Service::Base

    # @!method call(message_id:, guardian:, message:, upload_ids:)
    #   @param guardian [Guardian]
    #   @param message_id [Integer]
    #   @param message [String]
    #   @param upload_ids [Array<Integer>] IDs of uploaded documents

    contract
    model :message
    policy :can_modify_channel_message
    policy :can_modify_message

    transaction do
      step :modify_message
      step :ensures_message_validity
      step :save_message
      step :save_revision
      step :publish
    end

    class Contract
      attribute :message_id, :string
      attribute :message, :string
      attribute :upload_ids, :array

      validates :message_id, presence: true
      validates :message, presence: true, if: -> { upload_ids.blank? }
    end

    private

    def fetch_message(contract:, **)
      ::Chat::Message
        .strict_loading
        .includes(
          :chat_mentions,
          :bookmarks,
          :chat_webhook_event,
          :uploads,
          :revisions,
          chat_channel: [
            :last_message,
            :chat_channel_archive,
            chatable: [:topic_only_relative_url, direct_message_users: [user: :user_option]],
          ],
          user: :user_status,
        )
        .find_by(id: contract.message_id)
    end

    def can_modify_channel_message(guardian:, message:, **)
      guardian.can_modify_channel_message?(message.chat_channel)
    end

    def can_modify_message(guardian:, message:, **)
      guardian.can_edit_chat?(message)
    end

    def modify_message(contract:, message:, guardian:, **)
      message.message = contract.message
      message.last_editor_id = guardian.user.id

      return if contract.upload_ids.nil? || !SiteSetting.chat_allow_uploads

      uploads = ::Upload.where(id: contract.upload_ids, user_id: guardian.user.id)
      return if uploads.count != contract.upload_ids.count

      new_upload_ids = uploads.map(&:id)
      existing_upload_ids = message.upload_ids
      difference = (existing_upload_ids + new_upload_ids) - (existing_upload_ids & new_upload_ids)
      return if !difference.any?

      message.upload_ids = new_upload_ids
    end

    def ensures_message_validity(message:, **)
      message.valid?
    end

    def save_message(message:, **)
      message.cook
      message.save
      message.update_mentions
    end

    def save_revision(message:, guardian:, **)
      return if !should_create_revision?(message: message, guardian: guardian)

      context.revision =
        message.revisions.create!(
          old_message: message.message_before_last_save,
          new_message: message.message,
          user_id: guardian.user.id,
        )
    end

    def should_create_revision?(message:, guardian:, **)
      maxSeconds = SiteSetting.chat_editing_grace_period
      maxEditedChars =
        (
          if guardian.user.has_trust_level?(TrustLevel[2])
            SiteSetting.chat_editing_grace_period_max_diff_high_trust
          else
            SiteSetting.chat_editing_grace_period_max_diff_low_trust
          end
        )
      secondsSinceCreated = Time.now.to_i - message&.created_at.iso8601.to_time.to_i
      charsEdited =
        ONPDiff
          .new(message.message_before_last_save, message.message)
          .short_diff
          .sum { |str, type| type == :common ? 0 : str.size }

      secondsSinceCreated > maxSeconds || charsEdited > maxEditedChars
    end

    def publish(message:, guardian:, **)
      ::Chat::Publisher.publish_edit!(message.chat_channel, message)
      Jobs.enqueue(Jobs::Chat::ProcessMessage, { chat_message_id: message.id })

      edit_timestamp = context.revision&.created_at || Time.zone.now
      ::Chat::Notifier.notify_edit(chat_message: message, timestamp: edit_timestamp)
      DiscourseEvent.trigger(:chat_message_edited, message, message.chat_channel, guardian.user)

      if message.thread.present?
        ::Chat::Publisher.publish_thread_original_message_metadata!(message.thread)
      end
    end
  end
end
