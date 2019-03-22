import debounce from "discourse/lib/debounce";
import { i18n } from "discourse/lib/computed";
import AdminUser from "admin/models/admin-user";
import CanCheckEmails from "discourse/mixins/can-check-emails";

export default Ember.Controller.extend(CanCheckEmails, {
  model: null,
  query: null,
  order: null,
  ascending: null,
  showEmails: false,
  refreshing: false,
  listFilter: null,
  selectAll: false,

  queryNew: Ember.computed.equal("query", "new"),
  queryPending: Ember.computed.equal("query", "pending"),
  queryHasApproval: Ember.computed.or("queryNew", "queryPending"),
  showApproval: Ember.computed.and(
    "siteSettings.must_approve_users",
    "queryHasApproval"
  ),
  searchHint: i18n("search_hint"),
  hasSelection: Ember.computed.gt("selectedCount", 0),

  selectedCount: function() {
    var model = this.get("model");
    if (!model || !model.length) return 0;
    return model.filterBy("selected").length;
  }.property("model.@each.selected"),

  selectAllChanged: function() {
    var val = this.get("selectAll");
    this.get("model").forEach(function(user) {
      if (user.get("can_approve")) {
        user.set("selected", val);
      }
    });
  }.observes("selectAll"),

  title: function() {
    return I18n.t("admin.users.titles." + this.get("query"));
  }.property("query"),

  _filterUsers: debounce(function() {
    this._refreshUsers();
  }, 250).observes("listFilter"),

  _refreshUsers() {
    this.set("refreshing", true);

    AdminUser.findAll(this.get("query"), {
      filter: this.get("listFilter"),
      show_emails: this.get("showEmails"),
      order: this.get("order"),
      ascending: this.get("ascending")
    })
      .then(result => this.set("model", result))
      .finally(() => this.set("refreshing", false));
  },

  actions: {
    approveUsers: function() {
      AdminUser.bulkApprove(this.get("model").filterBy("selected"));
      this._refreshUsers();
    },

    rejectUsers: function() {
      var maxPostAge = this.siteSettings.delete_user_max_post_age;
      var controller = this;
      AdminUser.bulkReject(this.get("model").filterBy("selected")).then(
        function(result) {
          var message = I18n.t("admin.users.reject_successful", {
            count: result.success
          });
          if (result.failed > 0) {
            message +=
              " " +
              I18n.t("admin.users.reject_failures", { count: result.failed });
            message +=
              " " +
              I18n.t("admin.user.delete_forbidden", { count: maxPostAge });
          }
          bootbox.alert(message);
          controller._refreshUsers();
        }
      );
    },

    toggleEmailVisibility: function() {
      this.toggleProperty("showEmails");
      this._refreshUsers();
    }
  }
});
