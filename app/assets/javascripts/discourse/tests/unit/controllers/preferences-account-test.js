import { module, test } from "qunit";
import { setupTest } from "ember-qunit";

module("Unit | Controller | preferences/account", function (hooks) {
  setupTest(hooks);

  test("updating of associated accounts", function (assert) {
    const controller = this.owner.lookup("controller:preferences/account");
    controller.setProperties({
      siteSettings: {
        enable_google_oauth2_logins: true,
      },
      model: {
        id: 70,
        second_factor_enabled: true,
        is_anonymous: true,
      },
      currentUser: {
        id: 1234,
      },
      site: {
        isMobileDevice: false,
      },
    });

    assert.strictEqual(controller.canUpdateAssociatedAccounts, false);

    controller.set("model.second_factor_enabled", false);
    assert.strictEqual(controller.canUpdateAssociatedAccounts, false);

    controller.set("model.is_anonymous", false);
    assert.strictEqual(controller.canUpdateAssociatedAccounts, false);

    controller.set("model.id", 1234);
    assert.strictEqual(controller.canUpdateAssociatedAccounts, true);
  });
});
