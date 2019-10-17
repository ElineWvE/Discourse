import { ajax } from "discourse/lib/ajax";
import computed from "ember-addons/ember-computed-decorators";

export default Ember.Component.extend({
  classNames: ["badge-title"],

  saved: false,
  saving: false,

  @computed("saving")
  savingStatus(saving) {
    return saving ? I18n.t("saving") : I18n.t("save");
  },

  @computed("selectableUserBadges", "selectedUserBadgeId")
  selectedUserBadge(selectableUserBadges, selectedUserBadgeId) {
    selectedUserBadgeId = parseInt(selectedUserBadgeId);
    let selectedUserBadge = null;

    selectableUserBadges.forEach(function(userBadge) {
      if (userBadge.get("id") === selectedUserBadgeId) {
        selectedUserBadge = userBadge;
      }
    });
    return selectedUserBadge;
  },

  actions: {
    save() {
      this.setProperties({ saved: false, saving: true });

      const badge_id = this.selectedUserBadgeId || 0;

      ajax(this.currentUser.path + "/preferences/badge_title", {
        type: "PUT",
        data: { user_badge_id: badge_id }
      }).then(
        () => {
          this.setProperties({
            saved: true,
            saving: false
          });
          this.currentUser.set(
            "title",
            this.get("selectedUserBadge.badge.name")
          );
        },
        () => {
          bootbox.alert(I18n.t("generic_error"));
        }
      );
    }
  }
});
