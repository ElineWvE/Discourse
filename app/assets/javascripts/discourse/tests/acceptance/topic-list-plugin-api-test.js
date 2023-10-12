import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { withPluginApi } from "discourse/lib/plugin-api";
import { clearCustomLastUnreadUrlCallbacks } from "discourse/models/topic";
import { acceptance, query } from "discourse/tests/helpers/qunit-helpers";

acceptance("Topic list plugin API", function () {
  function customLastUnreadUrl(context) {
    return `${context.urlForPostNumber(1)}?overridden`;
  }

  test("Overrides lastUnreadUrl", async function (assert) {
    try {
      withPluginApi("1.2.0", (api) => {
        api.registerCustomLastUnreadUrlCallback(customLastUnreadUrl);
      });

      await visit("/");
      assert.strictEqual(
        query(
          ".topic-list .topic-list-item:first-child a.raw-topic-link"
        ).getAttribute("href"),
        "/t/error-after-upgrade-to-0-9-7-9/11557/1?overridden"
      );
    } finally {
      clearCustomLastUnreadUrlCallbacks();
    }
  });
});
