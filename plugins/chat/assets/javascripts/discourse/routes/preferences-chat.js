import RestrictedUserRoute from "discourse/routes/restricted-user";
import { defaultHomepage } from "discourse/lib/utilities";
import { inject as service } from "@ember/service";

export default class PreferencesChatRoute extends RestrictedUserRoute {
  @service chat;
  @service router;
  @service siteSettings;
  @service currentUser;

  showFooter = true;

  setupController(controller, user) {
    if (
      !this.siteSettings.chat_enabled ||
      (!user.can_chat && !this.currentUser?.admin)
    ) {
      return this.router.transitionTo(`discovery.${defaultHomepage()}`);
    }

    controller.set("model", user);
  }
}
