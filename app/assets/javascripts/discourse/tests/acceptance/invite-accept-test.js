import {
  acceptance,
  exists,
  queryAll,
} from "discourse/tests/helpers/qunit-helpers";
import { fillIn, visit } from "@ember/test-helpers";
import PreloadStore from "discourse/lib/preload-store";
import I18n from "I18n";
import { test } from "qunit";

function setAuthenticationData(hooks, json) {
  hooks.beforeEach(() => {
    const node = document.createElement("meta");
    node.dataset.authenticationData = JSON.stringify(json);
    node.id = "data-authentication";
    document.querySelector("head").appendChild(node);
  });
  hooks.afterEach(() => {
    document
      .querySelector("head")
      .removeChild(document.getElementById("data-authentication"));
  });
}

function preloadInvite({ link = false } = {}) {
  const info = {
    invited_by: {
      id: 123,
      username: "foobar",
      avatar_template: "/user_avatar/localhost/neil/{size}/25_1.png",
      name: "foobar",
      title: "team",
    },
    username: "invited",
  };

  if (link) {
    info.email = "null";
    info.is_invite_link = true;
  } else {
    info.email = "foobar@example.com";
    info.is_invite_link = false;
  }

  PreloadStore.store("invite_info", info);
}

acceptance("Invite accept", function (needs) {
  needs.settings({ full_name_required: true });

  test("email invite link", async function (assert) {
    PreloadStore.store("invite_info", {
      invited_by: {
        id: 123,
        username: "foobar",
        avatar_template: "/user_avatar/localhost/neil/{size}/25_1.png",
        name: "foobar",
        title: "team",
      },
      email: "foobar@example.com",
      username: "invited",
      is_invite_link: false,
    });

    await visit("/invites/myvalidinvitetoken");

    assert.ok(
      queryAll(".col-form")
        .text()
        .includes(I18n.t("invites.social_login_available")),
      "shows social login hint"
    );

    assert.ok(!exists("#new-account-email"), "hides the email input");
  });

  test("invite link", async function (assert) {
    PreloadStore.store("invite_info", {
      invited_by: {
        id: 123,
        username: "neil",
        avatar_template: "/user_avatar/localhost/neil/{size}/25_1.png",
        name: "Neil Lalonde",
        title: "team",
      },
      email: null,
      username: "invited",
      is_invite_link: true,
    });

    await visit("/invites/myvalidinvitetoken");
    assert.ok(exists("#new-account-email"), "shows the email input");
    assert.ok(exists("#new-account-username"), "shows the username input");
    assert.equal(
      queryAll("#new-account-username").val(),
      "invited",
      "username is prefilled"
    );
    assert.ok(exists("#new-account-name"), "shows the name input");
    assert.ok(exists("#new-account-password"), "shows the password input");
    assert.ok(
      exists(".invites-show .btn-primary:disabled"),
      "submit is disabled because name and email is not filled"
    );

    await fillIn("#new-account-name", "John Doe");
    assert.ok(
      exists(".invites-show .btn-primary:disabled"),
      "submit is disabled because email is not filled"
    );

    await fillIn("#new-account-email", "john.doe@example.com");
    assert.not(
      exists(".invites-show .btn-primary:disabled"),
      "submit is enabled"
    );

    await fillIn("#new-account-username", "a");
    assert.ok(exists(".username-input .bad"), "username is not valid");
    assert.ok(
      exists(".invites-show .btn-primary:disabled"),
      "submit is disabled"
    );

    await fillIn("#new-account-password", "aaa");
    assert.ok(exists(".password-input .bad"), "password is not valid");
    assert.ok(
      exists(".invites-show .btn-primary:disabled"),
      "submit is disabled"
    );

    await fillIn("#new-account-email", "john.doe@example");
    assert.ok(exists(".email-input .bad"), "email is not valid");
    assert.ok(
      exists(".invites-show .btn-primary:disabled"),
      "submit is disabled"
    );

    await fillIn("#new-account-username", "validname");
    await fillIn("#new-account-password", "secur3ty4Y0uAndMe");
    await fillIn("#new-account-email", "john.doe@example.com");
    assert.ok(exists(".username-input .good"), "username is valid");
    assert.ok(exists(".password-input .good"), "password is valid");
    assert.ok(exists(".email-input .good"), "email is valid");
    assert.not(
      exists(".invites-show .btn-primary:disabled"),
      "submit is enabled"
    );
  });
});

acceptance("Invite accept when local login is disabled", function (needs) {
  needs.settings({ enable_local_logins: false });

  test("invite link", async function (assert) {
    preloadInvite({ link: true });

    await visit("/invites/myvalidinvitetoken");

    assert.ok(exists(".btn-social.facebook"), "shows Facebook login button");
    assert.ok(!exists("form"), "does not display the form");
  });

  test("email invite link", async function (assert) {
    preloadInvite();
    await visit("/invites/myvalidinvitetoken");

    assert.ok(exists(".btn-social.facebook"), "shows Facebook login button");
    assert.ok(!exists("form"), "does not display the form");
  });
});

acceptance(
  "Invite accept when DiscourseConnect SSO is enabled and local login is disabled",
  function (needs) {
    needs.settings({
      enable_local_logins: false,
      enable_discourse_connect: true,
    });

    test("invite link", async function (assert) {
      preloadInvite({ link: true });

      await visit("/invites/myvalidinvitetoken");

      assert.ok(
        !exists(".btn-social.facebook"),
        "does not show Facebook login button"
      );
      assert.ok(!exists("form"), "does not display the form");
      assert.ok(
        !exists(".email-message"),
        "does not show the email message with the prefilled email"
      );
      assert.ok(
        exists(".btn-social.discourse-connect"),
        "shows the Accept and Continue button"
      );
    });

    test("email invite link", async function (assert) {
      preloadInvite();

      await visit("/invites/myvalidinvitetoken");

      assert.ok(
        !exists(".btn-social.facebook"),
        "does not show Facebook login button"
      );
      assert.ok(!exists("form"), "does not display the form");
      assert.ok(
        exists(".email-message"),
        "shows the email message with the prefilled email"
      );
      assert.ok(
        exists(".btn-social.discourse-connect"),
        "shows the Accept and Continue button"
      );
      assert.ok(
        queryAll(".email-message").text().includes("foobar@example.com")
      );
    });
  }
);

acceptance("Invite link with authentication data", function (needs) {
  needs.settings({ enable_local_logins: false });

  setAuthenticationData(needs.hooks, {
    auth_provider: "facebook",
    email: "blah@example.com",
    email_valid: true,
    username: "foobar",
    name: "barfoo",
  });

  test("form elements and buttons are correct ", async function (assert) {
    preloadInvite({ link: true });

    await visit("/invites/myvalidinvitetoken");

    assert.ok(
      !exists(".btn-social.facebook"),
      "does not show Facebook login button"
    );

    assert.ok(!exists("#new-account-password"), "does not show password field");

    assert.ok(
      exists("#new-account-email[disabled]"),
      "email field is disabled"
    );

    assert.equal(
      queryAll("#account-email-validation").text().trim(),
      I18n.t("user.email.authenticated", { provider: "Facebook" })
    );

    assert.equal(
      queryAll("#new-account-username").val(),
      "foobar",
      "username is prefilled"
    );

    assert.equal(
      queryAll("#new-account-name").val(),
      "barfoo",
      "name is prefilled"
    );
  });
});

acceptance("Email Invite link with authentication data", function (needs) {
  needs.settings({ enable_local_logins: false });

  setAuthenticationData(needs.hooks, {
    auth_provider: "facebook",
    email: "blah@example.com",
    email_valid: true,
    username: "foobar",
    name: "barfoo",
  });

  test("email invite link with authentication data when email does not match", async function (assert) {
    preloadInvite();

    await visit("/invites/myvalidinvitetoken");

    assert.equal(
      queryAll("#account-email-validation").text().trim(),
      I18n.t("user.email.invite_auth_email_invalid", { provider: "Facebook" })
    );

    assert.ok(!exists("form"), "does not display the form");
  });
});

acceptance(
  "Email Invite link with valid authentication data",
  function (needs) {
    needs.settings({ enable_local_logins: false });

    setAuthenticationData(needs.hooks, {
      auth_provider: "facebook",
      email: "foobar@example.com",
      email_valid: true,
      username: "foobar",
      name: "barfoo",
    });

    test("confirm form and buttons", async function (assert) {
      preloadInvite();

      await visit("/invites/myvalidinvitetoken");

      assert.ok(
        !exists(".btn-social.facebook"),
        "does not show Facebook login button"
      );

      assert.ok(
        !exists("#new-account-password"),
        "does not show password field"
      );
      assert.ok(!exists("#new-account-email"), "does not show email field");

      assert.equal(
        queryAll("#account-email-validation").text().trim(),
        I18n.t("user.email.authenticated", { provider: "Facebook" })
      );

      assert.equal(
        queryAll("#new-account-username").val(),
        "foobar",
        "username is prefilled"
      );

      assert.equal(
        queryAll("#new-account-name").val(),
        "barfoo",
        "name is prefilled"
      );
    });
  }
);
