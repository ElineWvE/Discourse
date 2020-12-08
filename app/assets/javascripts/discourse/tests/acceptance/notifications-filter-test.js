import { acceptance, queryAll } from "discourse/tests/helpers/qunit-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import { test } from "qunit";
import { visit } from "@ember/test-helpers";

acceptance("Notifications filter", function (needs) {
  needs.user();

  test("Notifications filter true", async function (assert) {
    await visit("/u/eviltrout/notifications");

    assert.ok(queryAll(".large-notification").length >= 0);
  });

  test("Notifications filter read", async function (assert) {
    await visit("/u/eviltrout/notifications");

    const dropdown = selectKit(".notifications-filter");
    await dropdown.expand();
    await dropdown.selectRowByValue("read");

    assert.ok(queryAll(".large-notification").length >= 0);
  });

  test("Notifications filter unread", async function (assert) {
    await visit("/u/eviltrout/notifications");

    const dropdown = selectKit(".notifications-filter");
    await dropdown.expand();
    await dropdown.selectRowByValue("unread");

    assert.ok(queryAll(".large-notification").length >= 0);
  });
});
