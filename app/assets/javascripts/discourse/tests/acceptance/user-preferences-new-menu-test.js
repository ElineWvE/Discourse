import { acceptance, exists } from "discourse/tests/helpers/qunit-helpers";
import { visit } from "@ember/test-helpers";
import { test } from "qunit";

acceptance(
  "New User Menu - Horizontal nav and preferences relocation",
  function (needs) {
    needs.user({
      redesigned_user_page_nav_enabled: true,
      user_api_keys: [
        {
          id: 1,
          application_name: "Discourse Hub",
          scopes: ["Read and clear notifications"],
          created_at: "2020-11-14T00:57:09.093Z",
          last_used_at: "2022-09-22T18:55:41.672Z",
        },
      ],
    });

    test("Can view user api keys on security page", async function (assert) {
      await visit("/u/eviltrout/preferences/security");
      assert.ok(exists(".control-group.apps"), "User can see apps section");
    });
  }
);
