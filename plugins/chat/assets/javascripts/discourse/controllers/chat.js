import Controller from "@ember/controller";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { FOOTER_NAV_ROUTES } from "discourse/plugins/chat/discourse/lib/chat-constants";

export default class ChatController extends Controller {
  @service chat;
  @service chatStateManager;
  @service router;

  get shouldUseChatSidebar() {
    if (this.site.mobileView) {
      return false;
    }

    if (this.shouldUseCoreSidebar) {
      return false;
    }

    return true;
  }

  get shouldUseCoreSidebar() {
    return this.siteSettings.navigation_menu === "sidebar";
  }

  get activeTab() {
    switch (this.router.currentRouteName) {
      case "chat.threads":
        return "threads";
      case "chat.direct-messages":
        return "direct-messages";
      case "chat.channels":
        return "channels";
    }
  }

  get shouldUseChatFooter() {
    return (
      this.site.mobileView &&
      FOOTER_NAV_ROUTES.includes(this.router.currentRouteName)
    );
  }

  get mainOutletModifierClasses() {
    let modifierClasses = [];

    if (this.chatStateManager.isSidePanelExpanded) {
      modifierClasses.push("has-side-panel-expanded");
    }

    if (
      !this.router.currentRouteName.startsWith("chat.channel.info") &&
      !this.router.currentRouteName.startsWith("chat.browse")
    ) {
      modifierClasses.push("chat-view");
    }

    return modifierClasses.join(" ");
  }

  @action
  onClickTab(tab) {
    switch (tab) {
      case "threads":
        return this.router.transitionTo("chat.threads");
      case "direct-messages":
        return this.router.transitionTo("chat.direct-messages");
      case "channels":
        return this.router.transitionTo("chat.channels");
    }
  }
}
