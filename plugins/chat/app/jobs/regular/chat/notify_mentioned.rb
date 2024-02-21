# frozen_string_literal: true

module Jobs
  module Chat
    class NotifyMentioned < ::Jobs::Base
      def execute(args)
        # fixme andrei preload user on mentions
        # fixme preload chat_channel and other stuff?
        @message = ::Chat::Message.find(args[:message_id])
        @parsed_mentions = @message.parsed_mentions
        return if @parsed_mentions.count > SiteSetting.max_mentions_per_chat_message

        @sender = @message.user
        @channel = @message.chat_channel

        notify_mentioned_users
        ::Chat::MentionsWarnings.send_for(@message)
      end

      private

      def get_mention(type, target_id = nil)
        @message.chat_mentions.where(type: type, target_id: target_id).first
      end

      def notify_mentioned_users
        @parsed_mentions.all_users_reached_by_mentions_info.each do |info|
          mentioned_user = info[:user]
          next if should_not_notify?(mentioned_user)

          mention = get_mention(info[:type], info[:target_id])
          mention.create_notification_for(mentioned_user)

          notify(mention, mentioned_user)
        end
      end

      def notify(mention, mentioned_user)
        membership = @channel.membership_for(mentioned_user) # fixme andrei take care of N + 1
        return if membership.muted?

        payload = mention.notification_payload(mentioned_user)
        unless membership.desktop_notifications_never?
          ::PostAlerter.desktop_notification(mentioned_user, payload)
        end
        unless membership.mobile_notifications_never?
          ::PostAlerter.push_notification(mentioned_user, payload)
        end
      end

      def should_not_notify?(mentioned_user)
        mentioned_user.suspended? || mentioned_user == @sender ||
          mentioned_user.doesnt_want_to_hear_from(@sender) || !mentioned_user.following?(@channel)
      end
    end
  end
end
