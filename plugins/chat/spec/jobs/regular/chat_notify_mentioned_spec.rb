# frozen_string_literal: true

require "rails_helper"

describe Jobs::ChatNotifyMentioned do
  fab!(:user_1) { Fabricate(:user) }
  fab!(:user_2) { Fabricate(:user) }
  fab!(:public_channel) { Fabricate(:category_channel) }

  let(:user_ids) { [user_2.id] }

  before do
    Group.refresh_automatic_groups!
    user_1.reload
    user_2.reload

    @chat_group = Fabricate(:group, users: [user_1, user_2])
    @personal_chat_channel =
      Chat::DirectMessageChannelCreator.create!(acting_user: user_1, target_users: [user_1, user_2])

    [user_1, user_2].each do |u|
      Fabricate(:user_chat_channel_membership, chat_channel: public_channel, user: u)
    end
  end

  def create_chat_message(channel: public_channel, user: user_1)
    Fabricate(:chat_message, chat_channel: channel, user: user, created_at: 10.minutes.ago)
  end

  def track_desktop_notification(
    user: user_2,
    message:,
    user_ids:,
    mention_type:
  )
    MessageBus
      .track_publish("/chat/notification-alert/#{user.id}") do
        subject.execute(
          chat_message_id: message.id,
          timestamp: message.created_at,
          user_ids: user_ids,
          mention_type: mention_type
        )
      end
      .first
  end

  def track_core_notification(user: user_2, message:, user_ids:, mention_type:)
    subject.execute(
      chat_message_id: message.id,
      timestamp: message.created_at,
      user_ids: user_ids,
      mention_type: mention_type
    )

    Notification.where(user: user, notification_type: Notification.types[:chat_mention]).last
  end

  describe "scenarios where we should skip sending notifications" do
    let(:mention_type) { Chat::ChatNotifier::HERE_MENTIONS }

    it "does nothing if there is a newer version of the message" do
      message = create_chat_message
      Fabricate(:chat_message_revision, chat_message: message, old_message: "a", new_message: "b")

      PostAlerter.expects(:push_notification).never

      desktop_notification =
        track_desktop_notification(message: message, user_ids: user_ids, mention_type: mention_type)
      expect(desktop_notification).to be_nil

      created_notification =
        Notification.where(user: user_2, notification_type: Notification.types[:chat_mention]).last
      expect(created_notification).to be_nil
    end

    it "does nothing when user is not following the channel" do
      message = create_chat_message

      UserChatChannelMembership.where(chat_channel: public_channel, user: user_2).update!(
        following: false,
      )

      PostAlerter.expects(:push_notification).never

      desktop_notification =
        track_desktop_notification(message: message, user_ids: user_ids, mention_type: mention_type)
      expect(desktop_notification).to be_nil

      created_notification =
        Notification.where(user: user_2, notification_type: Notification.types[:chat_mention]).last
      expect(created_notification).to be_nil
    end

    it "does nothing when user doesn't have a membership record" do
      message = create_chat_message

      UserChatChannelMembership.find_by(chat_channel: public_channel, user: user_2).destroy!

      PostAlerter.expects(:push_notification).never

      desktop_notification =
        track_desktop_notification(message: message, user_ids: user_ids, mention_type: mention_type)
      expect(desktop_notification).to be_nil

      created_notification =
        Notification.where(user: user_2, notification_type: Notification.types[:chat_mention]).last
      expect(created_notification).to be_nil
    end

    it "does nothing if we already created a mention for the user" do
      message = create_chat_message
      Fabricate(:chat_mention, chat_message: message, user: user_2)

      PostAlerter.expects(:push_notification).never

      desktop_notification =
        track_desktop_notification(message: message, user_ids: user_ids, mention_type: mention_type)
      expect(desktop_notification).to be_nil

      created_notification =
        Notification.where(user: user_2, notification_type: Notification.types[:chat_mention]).last
      expect(created_notification).to be_nil
    end

    it "works if the mention belongs to a different message" do
      message_1 = create_chat_message
      message_2 = create_chat_message

      Fabricate(:chat_mention, chat_message: message_1, user: user_2)

      PostAlerter.expects(:push_notification).once

      desktop_notification =
        track_desktop_notification(message: message_2, user_ids: user_ids, mention_type: mention_type)

      expect(desktop_notification).to be_present
    end

    it "does nothing if user is not participating in a private channel" do
      user_3 = Fabricate(:user)
      @chat_group.add(user_3)
      message = create_chat_message(channel: @personal_chat_channel)

      PostAlerter.expects(:push_notification).never

      desktop_notification =
        track_desktop_notification(
          message: message, user_ids: [user_3.id], mention_type: Chat::ChatNotifier::HERE_MENTIONS
        )
      expect(desktop_notification).to be_nil

      created_notification =
        Notification.where(user: user_3, notification_type: Notification.types[:chat_mention]).last
      expect(created_notification).to be_nil
    end

    it "skips desktop notifications based on user preferences" do
      message = create_chat_message
      UserChatChannelMembership.find_by(chat_channel: public_channel, user: user_2).update!(
        desktop_notification_level: UserChatChannelMembership::NOTIFICATION_LEVELS[:never],
      )

      desktop_notification =
        track_desktop_notification(message: message, user_ids: user_ids, mention_type: mention_type)

      expect(desktop_notification).to be_nil
    end

    it "skips push notifications based on user preferences" do
      message = create_chat_message
      UserChatChannelMembership.find_by(chat_channel: public_channel, user: user_2).update!(
        mobile_notification_level: UserChatChannelMembership::NOTIFICATION_LEVELS[:never],
      )

      PostAlerter.expects(:push_notification).never

      subject.execute(
        chat_message_id: message.id,
        timestamp: message.created_at,
        user_ids: user_ids,
        mention_type: mention_type
      )
    end

    it "skips desktop notifications based on user muting preferences" do
      message = create_chat_message
      UserChatChannelMembership.find_by(chat_channel: public_channel, user: user_2).update!(
        desktop_notification_level: UserChatChannelMembership::NOTIFICATION_LEVELS[:always],
        muted: true,
      )

      desktop_notification =
        track_desktop_notification(message: message, user_ids: user_ids, mention_type: mention_type)

      expect(desktop_notification).to be_nil
    end

    it "skips push notifications based on user muting preferences" do
      message = create_chat_message
      UserChatChannelMembership.find_by(chat_channel: public_channel, user: user_2).update!(
        mobile_notification_level: UserChatChannelMembership::NOTIFICATION_LEVELS[:always],
        muted: true,
      )

      PostAlerter.expects(:push_notification).never

      subject.execute(
        chat_message_id: message.id,
        timestamp: message.created_at,
        user_ids: user_ids,
        mention_type: mention_type
      )
    end

    it "does nothing when the mention type is invalid" do
      message = create_chat_message

      PostAlerter.expects(:push_notification).never

      desktop_notification =
        track_desktop_notification(message: message, user_ids: user_ids, mention_type: "invalid")
      expect(desktop_notification).to be_nil

      created_notification =
        Notification.where(user: user_2, notification_type: Notification.types[:chat_mention]).last
      expect(created_notification).to be_nil
    end

    context "when the user is muting the message sender" do
      it "does not send notifications to the user who is muting the acting user" do
        Fabricate(:muted_user, user: user_2, muted_user: user_1)
        message = create_chat_message

        PostAlerter.expects(:push_notification).never

        desktop_notification =
          track_desktop_notification(message: message, user_ids: user_ids, mention_type: mention_type)
        expect(desktop_notification).to be_nil

        created_notification =
          Notification.where(user: user_2, notification_type: Notification.types[:chat_mention]).last
        expect(created_notification).to be_nil
      end

      it "does not send notifications to the user who is ignoring the acting user" do
        Fabricate(:ignored_user, user: user_2, ignored_user: user_1, expiring_at: 1.day.from_now)
        message = create_chat_message

        PostAlerter.expects(:push_notification).never

        desktop_notification =
          track_desktop_notification(message: message, user_ids: user_ids, mention_type: mention_type)
        expect(desktop_notification).to be_nil

        created_notification =
          Notification.where(user: user_2, notification_type: Notification.types[:chat_mention]).last
        expect(created_notification).to be_nil
      end
    end
  end

  shared_examples "creates different notifications with basic data" do
    let(:expected_channel_title) { public_channel.title(user_2) }

    it "works for desktop notifications" do
      message = create_chat_message

      desktop_notification =
        track_desktop_notification(message: message, user_ids: user_ids, mention_type: mention_type)

      expect(desktop_notification).to be_present
      expect(desktop_notification.data[:notification_type]).to eq(Notification.types[:chat_mention])
      expect(desktop_notification.data[:username]).to eq(user_1.username)
      expect(desktop_notification.data[:tag]).to eq(
        Chat::ChatNotifier.push_notification_tag(:mention, public_channel.id),
      )
      expect(desktop_notification.data[:excerpt]).to eq(message.push_notification_excerpt)
      expect(desktop_notification.data[:post_url]).to eq(
        "/chat/channel/#{public_channel.id}/#{public_channel.slug}?messageId=#{message.id}",
      )
    end

    it "works for push notifications" do
      message = create_chat_message

      PostAlerter.expects(:push_notification).with(
        user_2,
        {
          notification_type: Notification.types[:chat_mention],
          username: user_1.username,
          tag: Chat::ChatNotifier.push_notification_tag(:mention, public_channel.id),
          excerpt: message.push_notification_excerpt,
          post_url:
            "/chat/channel/#{public_channel.id}/#{public_channel.slug}?messageId=#{message.id}",
          translated_title: payload_translated_title,
        },
      )

      subject.execute(
        chat_message_id: message.id,
        timestamp: message.created_at,
        user_ids: user_ids,
        mention_type: mention_type
      )
    end

    it "works for core notifications" do
      message = create_chat_message

      created_notification =
        track_core_notification(message: message, user_ids: user_ids, mention_type: mention_type)

      expect(created_notification).to be_present
      expect(created_notification.high_priority).to eq(true)
      expect(created_notification.read).to eq(false)

      data_hash = created_notification.data_hash

      expect(data_hash[:chat_message_id]).to eq(message.id)
      expect(data_hash[:chat_channel_id]).to eq(public_channel.id)
      expect(data_hash[:mentioned_by_username]).to eq(user_1.username)
      expect(data_hash[:is_direct_message_channel]).to eq(false)
      expect(data_hash[:chat_channel_title]).to eq(expected_channel_title)
      expect(data_hash[:chat_channel_slug]).to eq(public_channel.slug)

      chat_mention =
        ChatMention.where(notification: created_notification, user: user_2, chat_message: message)
      expect(chat_mention).to be_present
    end

    it "works for publishing new mention updates" do
      message = create_chat_message

      new_mention = MessageBus
        .track_publish(ChatPublisher.new_mentions_message_bus_channel(message.chat_channel_id)) do
          subject.execute(
            chat_message_id: message.id,
            timestamp: message.created_at,
            user_ids: user_ids,
            mention_type: mention_type
          )
        end.first

      expect(new_mention).to be_present
      expect(new_mention.data["message_id"]).to eq(message.id)
      expect(new_mention.data["channel_id"]).to eq(message.chat_channel_id)
    end
  end

  describe "#execute" do
    describe "global mention notifications" do
      let(:mention_type) { Chat::ChatNotifier::GLOBAL_MENTIONS }

      let(:payload_translated_title) do
        I18n.t(
          "discourse_push_notifications.popup.chat_mention.other_type",
          username: user_1.username,
          identifier: "@all",
          channel: public_channel.title(user_2),
        )
      end

      include_examples "creates different notifications with basic data"

      it "includes global mention specific data to core notifications" do
        message = create_chat_message

        created_notification =
          track_core_notification(message: message, user_ids: user_ids, mention_type: mention_type)

        data_hash = created_notification.data_hash

        expect(data_hash[:identifier]).to eq("all")
      end

      it "includes global mention specific data to desktop notifications" do
        message = create_chat_message

        desktop_notification =
          track_desktop_notification(message: message, user_ids: user_ids, mention_type: mention_type)

        expect(desktop_notification.data[:translated_title]).to eq(payload_translated_title)
      end

      context "with private channels" do
        it "users a different translated title" do
          message = create_chat_message(channel: @personal_chat_channel)

          desktop_notification =
            track_desktop_notification(message: message, user_ids: user_ids, mention_type: mention_type)

          expected_title =
            I18n.t(
              "discourse_push_notifications.popup.direct_message_chat_mention.other_type",
              username: user_1.username,
              identifier: "@all",
            )

          expect(desktop_notification.data[:translated_title]).to eq(expected_title)
        end
      end
    end

    describe "here mention notifications" do
      let(:mention_type) { Chat::ChatNotifier::HERE_MENTIONS }

      let(:payload_translated_title) do
        I18n.t(
          "discourse_push_notifications.popup.chat_mention.other_type",
          username: user_1.username,
          identifier: "@here",
          channel: public_channel.title(user_2),
        )
      end

      include_examples "creates different notifications with basic data"

      it "includes here mention specific data to core notifications" do
        message = create_chat_message

        created_notification =
          track_core_notification(message: message, user_ids: user_ids, mention_type: mention_type)
        data_hash = created_notification.data_hash

        expect(data_hash[:identifier]).to eq("here")
      end

      it "includes here mention specific data to desktop notifications" do
        message = create_chat_message

        desktop_notification =
          track_desktop_notification(message: message, user_ids: user_ids, mention_type: mention_type)

        expect(desktop_notification.data[:translated_title]).to eq(payload_translated_title)
      end

      context "with private channels" do
        it "users a different translated title" do
          message = create_chat_message(channel: @personal_chat_channel)

          desktop_notification =
            track_desktop_notification(message: message, user_ids: user_ids, mention_type: mention_type)

          expected_title =
            I18n.t(
              "discourse_push_notifications.popup.direct_message_chat_mention.other_type",
              username: user_1.username,
              identifier: "@here",
            )

          expect(desktop_notification.data[:translated_title]).to eq(expected_title)
        end
      end
    end

    describe "direct mention notifications" do
      let(:mention_type) { Chat::ChatNotifier::DIRECT_MENTIONS }

      let(:payload_translated_title) do
        I18n.t(
          "discourse_push_notifications.popup.chat_mention.direct",
          username: user_1.username,
          identifier: "",
          channel: public_channel.title(user_2),
        )
      end

      include_examples "creates different notifications with basic data"

      it "includes here mention specific data to core notifications" do
        message = create_chat_message

        created_notification =
          track_core_notification(message: message, user_ids: user_ids, mention_type: mention_type)
        data_hash = created_notification.data_hash

        expect(data_hash[:identifier]).to be_nil
      end

      it "includes here mention specific data to desktop notifications" do
        message = create_chat_message

        desktop_notification =
          track_desktop_notification(message: message, user_ids: user_ids, mention_type: mention_type)

        expect(desktop_notification.data[:translated_title]).to eq(payload_translated_title)
      end

      context "with private channels" do
        it "users a different translated title" do
          message = create_chat_message(channel: @personal_chat_channel)

          desktop_notification =
            track_desktop_notification(message: message, user_ids: user_ids, mention_type: mention_type)

          expected_title =
            I18n.t(
              "discourse_push_notifications.popup.direct_message_chat_mention.direct",
              username: user_1.username,
              identifier: "",
            )

          expect(desktop_notification.data[:translated_title]).to eq(expected_title)
        end
      end
    end

    describe "group mentions" do
      let(:mention_type) { @chat_group.name.to_sym }

      let(:payload_translated_title) do
        I18n.t(
          "discourse_push_notifications.popup.chat_mention.other_type",
          username: user_1.username,
          identifier: "@#{@chat_group.name}",
          channel: public_channel.title(user_2),
        )
      end

      include_examples "creates different notifications with basic data"

      it "includes here mention specific data to core notifications" do
        message = create_chat_message

        created_notification =
          track_core_notification(message: message, user_ids: user_ids, mention_type: mention_type)
        data_hash = created_notification.data_hash

        expect(data_hash[:identifier]).to eq(@chat_group.name)
        expect(data_hash[:is_group_mention]).to eq(true)
      end

      it "includes here mention specific data to desktop notifications" do
        message = create_chat_message

        desktop_notification =
          track_desktop_notification(message: message,  user_ids: user_ids, mention_type: mention_type)

        expect(desktop_notification.data[:translated_title]).to eq(payload_translated_title)
      end

      context "with private channels" do
        it "users a different translated title" do
          message = create_chat_message(channel: @personal_chat_channel)

          desktop_notification =
            track_desktop_notification(message: message, user_ids: user_ids, mention_type: mention_type)

          expected_title =
            I18n.t(
              "discourse_push_notifications.popup.direct_message_chat_mention.other_type",
              username: user_1.username,
              identifier: "@#{@chat_group.name}",
            )

          expect(desktop_notification.data[:translated_title]).to eq(expected_title)
        end
      end
    end
  end
end
