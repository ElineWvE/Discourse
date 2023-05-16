import Controller from "@ember/controller";
import discourseComputed from "discourse-common/utils/decorators";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { getSaveAttributeForPreferencesController } from "discourse/lib/preferences-controllers-save-attrs-register";

export default Controller.extend({
  init() {
    this._super(...arguments);

    this.saveAttrNames = [
      "muted_tags",
      "tracked_tags",
      "watched_tags",
      "watching_first_post_tags",
    ];
  },

  @discourseComputed(
    "model.watched_tags.[]",
    "model.watching_first_post_tags.[]",
    "model.tracked_tags.[]",
    "model.muted_tags.[]"
  )
  selectedTags(watched, watchedFirst, tracked, muted) {
    return [].concat(watched, watchedFirst, tracked, muted).filter((t) => t);
  },

  actions: {
    save() {
      this.set("saved", false);
      return this.model
        .save(
          this.saveAttrNames.concat(
            getSaveAttributeForPreferencesController("tags")
          )
        )
        .then(() => {
          this.set("saved", true);
        })
        .catch(popupAjaxError);
    },
  },
});
