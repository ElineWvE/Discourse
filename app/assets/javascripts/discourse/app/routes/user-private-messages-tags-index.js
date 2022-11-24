import DiscourseRoute from "discourse/routes/discourse";
import EmberObject from "@ember/object";
import I18n from "I18n";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default DiscourseRoute.extend({
  model() {
    const username = this.modelFor("user").get("username_lower");

    return ajax(`/tags/personal_messages/${username}`)
      .then((result) => {
        return result.tags.map((tag) => EmberObject.create(tag));
      })
      .catch(popupAjaxError);
  },

  titleToken() {
    return [I18n.t("tagging.tags"), I18n.t("user.private_messages")];
  },

  setupController(controller, model) {
    controller.setProperties({
      model,
      sortProperties: this.siteSettings.tags_sort_alphabetically
        ? ["id"]
        : ["count:desc", "id"],
      tagsForUser: this.modelFor("user").get("username_lower"),
    });

    this.controllerFor("user-topics-list").setProperties({
      showToggleBulkSelect: false,
      selected: [],
    });

    this.controllerFor("user-private-messages").setProperties({
      pmView: "tags",
    });
  },
});
