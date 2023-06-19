import Controller, { inject as controller } from "@ember/controller";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";
import I18n from "I18n";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { Promise } from "rsvp";
import Topic from "discourse/models/topic";
import ChangeCategory from "../components/bulk-actions/change-category";
import NotificationLevel from "../components/bulk-actions/notification-level";
import ChangeTags from "../components/bulk-actions/change-tags";
import AppendTags from "../components/bulk-actions/append-tags";

const _buttons = [];

export function addBulkButton(opts) {
  _buttons.push({
    label: `topics.bulk.${opts.label}`,
    icon: opts.icon,
    class: opts.class,
    buttonVisible: opts.buttonVisible || (() => true),
    enabledSetting: opts.enabledSetting,
    action: opts.action,
  });
}

// Modal for performing bulk actions on topics
export default class TopicBulkActions extends Controller.extend(
  ModalFunctionality
) {
  @service dialog;
  @controller("user-private-messages") userPrivateMessages;

  loading = false;
  showProgress = false;
  processedTopicCount = 0;
  activeComponent = null;

  constructor() {
    super(...arguments);

    // Add default buttons
    addBulkButton({
      label: "change_category",
      icon: "pencil-alt",
      class: "btn-default",
      buttonVisible: (topics) => !topics.some((t) => t.isPrivateMessage),
      action: () => this.set("activeComponent", ChangeCategory),
    });

    addBulkButton({
      label: "close_topics",
      icon: "lock",
      class: "btn-default",
      buttonVisible: (topics) => !topics.some((t) => t.isPrivateMessage),
      action: () =>
        this.forEachPerformed({ type: "close" }, (t) => t.set("closed", true)),
    });

    addBulkButton({
      label: "archive_topics",
      icon: "folder",
      class: "btn-default",
      buttonVisible: (topics) => !topics.some((t) => t.isPrivateMessage),
      action: () =>
        this.forEachPerformed({ type: "archive" }, (t) =>
          t.set("archived", true)
        ),
    });

    addBulkButton({
      label: "archive_topics",
      icon: "folder",
      class: "btn-default",
      buttonVisible: (topics) => topics.some((t) => t.isPrivateMessage),
      action: () => {
        let params = { type: "archive_messages" };
        if (this.userPrivateMessages.isGroup) {
          params.group = this.userPrivateMessages.groupFilter;
        }
        this.performAndRefresh(params);
      },
    });

    addBulkButton({
      label: "move_messages_to_inbox",
      icon: "folder",
      class: "btn-default",
      buttonVisible: (topics) => topics.some((t) => t.isPrivateMessage),
      action: () => {
        let params = { type: "move_messages_to_inbox" };
        if (this.userPrivateMessages.isGroup) {
          params.group = this.userPrivateMessages.groupFilter;
        }
        this.performAndRefresh(params);
      },
    });

    addBulkButton({
      label: "notification_level",
      icon: "d-regular",
      class: "btn-default",
      action: () => this.set("activeComponent", NotificationLevel),
    });

    addBulkButton({
      label: "defer",
      icon: "circle",
      class: "btn-default",
      buttonVisible: () => this.currentUser.user_option.enable_defer,
      action: () => this.performAndRefresh({ type: "destroy_post_timing" }),
    });

    addBulkButton({
      label: "unlist_topics",
      icon: "far-eye-slash",
      class: "btn-default",
      buttonVisible: (topics) =>
        topics.some((t) => t.visible) &&
        !topics.some((t) => t.isPrivateMessage),
      action: () =>
        this.forEachPerformed({ type: "unlist" }, (t) =>
          t.set("visible", false)
        ),
    });

    addBulkButton({
      label: "relist_topics",
      icon: "far-eye",
      class: "btn-default",
      buttonVisible: (topics) =>
        topics.some((t) => !t.visible) &&
        !topics.some((t) => t.isPrivateMessage),
      action: () =>
        this.forEachPerformed({ type: "relist" }, (t) =>
          t.set("visible", true)
        ),
    });

    addBulkButton({
      label: "reset_bump_dates",
      icon: "anchor",
      class: "btn-default",
      buttonVisible: () => this.currentUser.canManageTopic,
      action: () => this.performAndRefresh({ type: "reset_bump_dates" }),
    });

    addBulkButton({
      label: "change_tags",
      icon: "tag",
      class: "btn-default",
      enabledSetting: "tagging_enabled",
      buttonVisible: () => this.currentUser.canManageTopic,
      action: () => this.set("activeComponent", ChangeTags),
    });

    addBulkButton({
      label: "append_tags",
      icon: "tag",
      class: "btn-default",
      enabledSetting: "tagging_enabled",
      buttonVisible: () => this.currentUser.canManageTopic,
      action: () => this.set("activeComponent", AppendTags),
    });

    addBulkButton({
      label: "remove_tags",
      icon: "tag",
      class: "btn-default",
      enabledSetting: "tagging_enabled",
      buttonVisible: () => this.currentUser.canManageTopic,
      action: () => {
        this.dialog.deleteConfirm({
          message: I18n.t("topics.bulk.confirm_remove_tags", {
            count: this.model.topics.length,
          }),
          didConfirm: () => this.performAndRefresh({ type: "remove_tags" }),
        });
      },
    });

    addBulkButton({
      label: "delete",
      icon: "trash-alt",
      class: "btn-danger delete-topics",
      buttonVisible: () => this.currentUser.staff,
      action: () => this.performAndRefresh({ type: "delete" }),
    });
  }

  onShow() {
    this.set(
      "buttons",
      _buttons.filter((b) => {
        if (b.enabledSetting && !this.siteSettings[b.enabledSetting]) {
          return false;
        }
        return b.buttonVisible.call(this, this.model.topics);
      })
    );

    this.modal.set("modalClass", "topic-bulk-actions-modal small");
    this.set("activeComponent", null);
  }

  async perform(operation) {
    this.set("loading", true);

    if (this.model.topics.length > 20) {
      this.set("showProgress", true);
    }

    try {
      return this._processChunks(operation);
    } catch {
      this.dialog.alert(I18n.t("generic_error"));
    } finally {
      this.set("loading", false);
      this.set("processedTopicCount", 0);
      this.set("showProgress", false);
    }
  }

  _generateTopicChunks(allTopics) {
    let startIndex = 0;
    const chunkSize = 30;
    const chunks = [];

    while (startIndex < allTopics.length) {
      let topics = allTopics.slice(startIndex, startIndex + chunkSize);
      chunks.push(topics);
      startIndex += chunkSize;
    }

    return chunks;
  }

  _processChunks(operation) {
    const allTopics = this.model.topics;
    const topicChunks = this._generateTopicChunks(allTopics);
    const topicIds = [];

    const tasks = topicChunks.map((topics) => async () => {
      const result = await Topic.bulkOperation(topics, operation);
      this.set("processedTopicCount", this.processedTopicCount + topics.length);
      return result;
    });

    return new Promise((resolve, reject) => {
      const resolveNextTask = async () => {
        if (tasks.length === 0) {
          const topics = topicIds.map((id) => allTopics.findBy("id", id));
          return resolve(topics);
        }

        const task = tasks.shift();

        try {
          const result = await task();
          if (result?.topic_ids) {
            topicIds.push(...result.topic_ids);
          }
          resolveNextTask();
        } catch {
          reject();
        }
      };

      resolveNextTask();
    });
  }

  @action
  async forEachPerformed(operation, cb) {
    const topics = await this.perform(operation);

    if (topics) {
      topics.forEach(cb);
      this.refreshClosure?.();
      this.send("closeModal");
    }
  }

  @action
  async performAndRefresh(operation) {
    await this.perform(operation);

    this.refreshClosure?.();
    this.send("closeModal");
  }
}
