import I18n from "I18n";

import { tracked } from "@glimmer/tracking";

import { bind } from "discourse-common/utils/decorators";
import BaseTagSectionLink from "discourse/lib/sidebar/user/tags-section/base-tag-section-link";
import { UNREAD_LIST_DESTINATION } from "discourse/controllers/preferences/sidebar";

export default class TagSectionLink extends BaseTagSectionLink {
  @tracked totalUnread = 0;
  @tracked totalNew = 0;

  constructor({ topicTrackingState, currentUser }) {
    super(...arguments);
    this.topicTrackingState = topicTrackingState;
    this.currentUser = currentUser;
    this.refreshCounts();
  }

  @bind
  refreshCounts() {
    this.totalUnread = this.topicTrackingState.countUnread({
      tagId: this.tagName,
    });

    if (this.totalUnread === 0) {
      this.totalNew = this.topicTrackingState.countNew({
        tagId: this.tagName,
      });
    }
  }

  get models() {
    return [this.tagName];
  }

  get route() {
    if (this.currentUser?.sidebarListDestination === UNREAD_LIST_DESTINATION) {
      if (this.totalUnread > 0) {
        return "tag.showUnread";
      }
      if (this.totalNew > 0) {
        return "tag.showNew";
      }
    }
    return "tag.show";
  }

  get currentWhen() {
    return "tag.show tag.showNew tag.showUnread tag.showTop";
  }

  get badgeText() {
    if (this.totalUnread > 0) {
      return I18n.t("sidebar.unread_count", {
        count: this.totalUnread,
      });
    } else if (this.totalNew > 0) {
      return I18n.t("sidebar.new_count", {
        count: this.totalNew,
      });
    }
  }
}
