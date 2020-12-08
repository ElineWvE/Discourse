import { discourseModule } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";

discourseModule("Unit | Controller | preferences/second-factor", function () {
  test("displayOAuthWarning when OAuth login methods are enabled", function (assert) {
    const controller = this.owner.lookup(
      "controller:preferences/second-factor"
    );
    controller.setProperties({
      siteSettings: {
        enable_google_oauth2_logins: true,
      },
    });

    assert.equal(controller.get("displayOAuthWarning"), true);
  });
});
