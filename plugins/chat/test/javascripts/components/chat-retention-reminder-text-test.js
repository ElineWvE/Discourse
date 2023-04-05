import ChatChannel from "discourse/plugins/chat/discourse/models/chat-channel";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import hbs from "htmlbars-inline-precompile";
import I18n from "I18n";
import { module, test } from "qunit";
import { render } from "@ember/test-helpers";

module(
  "Discourse Chat | Component | chat-retention-reminder-text",
  function (hooks) {
    setupRenderingTest(hooks);

    test("when setting is set on 0", async function (assert) {
      this.channel = ChatChannel.create({ chatable_type: "Category" });
      this.siteSettings.chat_channel_retention_days = 0;

      await render(
        hbs`<ChatRetentionReminderText @channel={{this.channel}} />`
      );

      assert
        .dom(".chat-retention-reminder-text")
        .includesText(I18n.t("chat.retention_reminders.public_none"));
    });

    test("when channel is a public channel", async function (assert) {
      const count = 10;
      this.channel = ChatChannel.create({ chatable_type: "Category" });
      this.siteSettings.chat_channel_retention_days = count;

      await render(
        hbs`<ChatRetentionReminderText @channel={{this.channel}} />`
      );

      assert
        .dom(".chat-retention-reminder-text")
        .includesText(I18n.t("chat.retention_reminders.public", { count }));
    });

    test("when channel is a DM channel", async function (assert) {
      const count = 10;
      this.channel = ChatChannel.create({
        chatable_type: "DirectMessage",
      });
      this.siteSettings.chat_dm_retention_days = count;

      await render(
        hbs`<ChatRetentionReminderText @channel={{this.channel}} />`
      );

      assert
        .dom(".chat-retention-reminder-text")
        .includesText(I18n.t("chat.retention_reminders.dm", { count }));
    });
  }
);
