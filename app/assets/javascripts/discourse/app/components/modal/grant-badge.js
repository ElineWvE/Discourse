import { action } from "@ember/object";
import { empty } from "@ember/object/computed";
import { tracked } from "@glimmer/tracking";
import Component from "@glimmer/component";
import Badge from "discourse/models/badge";
import I18n from "I18n";
import UserBadge from "discourse/models/user-badge";
import { extractError } from "discourse/lib/ajax-error";
import getURL from "discourse-common/lib/get-url";
import {
  grantableBadges,
  isBadgeGrantable,
} from "discourse/lib/grant-badge-utils";

export default class GrantBadgeModal extends Component {
  @tracked loading = true;
  @tracked saving = false;
  @tracked selectedBadgeId = null;
  @tracked flash = null;
  @tracked flashType = null;
  @tracked allBadges = [];
  @tracked userBadges = [];
  @empty("availableBadges") noAvailableBadges;

  get post() {
    return this.args.model.selectedPost;
  }

  get availableBadges() {
    return grantableBadges(this.allBadges, this.userBadges);
  }

  get buttonDisabled() {
    return (
      this.saving ||
      !isBadgeGrantable(this.selectedBadgeId, this.availableBadges)
    );
  }

  @action
  async loadBadges() {
    this.loading = true;
    try {
      this.allBadges = await Badge.findAll();
      this.userBadges = await UserBadge.findByUsername(this.post.username);
    } catch (e) {
      this.flash = extractError(e);
      this.flashType = "error";
    } finally {
      this.loading = false;
    }
  }
  @action
  async performGrantBadge() {
    try {
      this.saving = true;
      const username = this.post.username;
      const newBadge = await UserBadge.grant(
        this.selectedBadgeId,
        username,
        getURL(this.post.url)
      );
      this.userBadges.pushObject(newBadge);
      this.selectedBadgeId = null;
      this.flash = I18n.t("badges.successfully_granted", {
        username,
        badge: newBadge.get("badge.name"),
      });
      this.flashType = "success";
    } catch (e) {
      this.flash = extractError(e);
      this.flashType = "error";
    } finally {
      this.saving = false;
    }
  }
}
