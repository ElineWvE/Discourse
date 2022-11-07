# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReviewableChatMessage, type: :model do
  fab!(:moderator) { Fabricate(:moderator) }
  fab!(:user) { Fabricate(:user) }
  fab!(:chat_channel) { Fabricate(:chat_channel) }
  fab!(:chat_message) { Fabricate(:chat_message, chat_channel: chat_channel, user: user) }
  fab!(:reviewable) do
    Fabricate(:reviewable_chat_message, target: chat_message, created_by: moderator)
  end

  it "agree_and_keep agrees with the flag and doesn't delete the message" do
    reviewable.perform(moderator, :agree_and_keep_message)

    expect(reviewable).to be_approved
    expect(chat_message.reload.deleted_at).not_to be_present
  end

  it "agree_and_delete agrees with the flag and deletes the message" do
    chat_message_id = chat_message.id
    reviewable.perform(moderator, :agree_and_delete)

    expect(reviewable).to be_approved
    expect(ChatMessage.with_deleted.find_by(id: chat_message_id).deleted_at).to be_present
  end

  it "agree_and_restore agrees with the flag and restores the message" do
    chat_message.trash!(user)
    reviewable.perform(moderator, :agree_and_restore)

    expect(reviewable).to be_approved
    expect(chat_message.reload.deleted_at).not_to be_present
  end

  it "perform_disagree disagrees with the flag and does nothing" do
    reviewable.perform(moderator, :disagree)

    expect(reviewable).to be_rejected
    expect(chat_message.reload.deleted_at).not_to be_present
  end

  it "perform_disagree_and_restore disagrees with the flag and does nothing" do
    chat_message.trash!(user)
    reviewable.perform(moderator, :disagree_and_restore)

    expect(reviewable).to be_rejected
    expect(chat_message.reload.deleted_at).to be_present
  end

  it "perform_ignore ignores the flag and does nothing" do
    reviewable.perform(moderator, :ignore)

    expect(reviewable).to be_ignored
    expect(chat_message.reload.deleted_at).not_to be_present
  end
end
