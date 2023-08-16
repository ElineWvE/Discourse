import { next } from "@ember/runloop";
import cookie, { removeCookie } from "discourse/lib/cookie";
import { getURL } from "discourse/lib/url";
import EmberObject from "@ember/object";
import showModal from "discourse/lib/show-modal";
import LoginModal from "discourse/components/modal/login";

// This is happening outside of the app via popup
const AuthErrors = [
  "requires_invite",
  "awaiting_approval",
  "awaiting_activation",
  "admin_not_allowed_from_ip_address",
  "not_allowed_from_ip_address",
];

export default {
  after: "inject-objects",
  initialize(owner) {
    let lastAuthResult;

    if (document.getElementById("data-authentication")) {
      // Happens for full screen logins
      lastAuthResult = document.getElementById("data-authentication").dataset
        .authenticationData;
    }

    // if (lastAuthResult) {
    const router = owner.lookup("router:main");
    router.one("didTransition", () => {
      next(() => {
        if (router.currentPath === "invites.show") {
          owner
            .lookup("invites.show")
            .authenticationComplete(JSON.parse(lastAuthResult));
        } else {
          // const options = JSON.parse(JSON.parse(lastAuthResult));
          const options = {};
          const modal = owner.lookup("service:modal");
          const siteSettings = owner.lookup("service:site-settings");
          const applicationRouter = owner.lookup("application:main");
          const applicationController = owner.lookup("controller:application");

          const loginError = (errorMsg, className, props, callback) => {
            modal.show(LoginModal, {
              model: {
                showNotActivated: (props) =>
                  applicationRouter.send("showNotActivated", props).bind(owner),
                showCreateAccount: (props) =>
                  applicationRouter
                    .send("showCreateAccount", props)
                    .bind(owner),
                canSignUp: applicationController.canSignUp,
                flash: errorMsg,
                flashType: className || "success",
                awaitingApproval: options.awaiting_approval,
                ...props,
              },
            });
            next(() => callback?.());
          };

          // if (options.omniauth_disallow_totp) {
          if (true) {
            return loginError(
              I18n.t("login.omniauth_disallow_totp"),
              "error",
              {
                loginName: options.email,
                showLoginButtons: false,
              },
              () => document.getElementById("login-account-password").focus()
            );
          }

          for (let i = 0; i < AuthErrors.length; i++) {
            const cond = AuthErrors[i];
            if (options[cond]) {
              return loginError(I18n.t(`login.${cond}`));
            }
          }

          if (options.suspended) {
            return loginError(options.suspended_message, "error");
          }

          // Reload the page if we're authenticated
          if (options.authenticated) {
            const destinationUrl =
              cookie("destination_url") || options.destination_url;
            if (destinationUrl) {
              // redirect client to the original URL
              removeCookie("destination_url");
              window.location.href = destinationUrl;
            } else if (window.location.pathname === getURL("/login")) {
              window.location = getURL("/");
            } else {
              window.location.reload();
            }
            return;
          }

          const skipConfirmation = siteSettings.auth_skip_create_confirm;
          owner.lookup("controller:createAccount").setProperties({
            accountEmail: options.email,
            accountUsername: options.username,
            accountName: options.name,
            authOptions: EmberObject.create(options),
            skipConfirmation,
          });

          next(() => {
            showModal("create-account", {
              modalClass: "create-account",
              titleAriaElementId: "create-account-title",
            });
          });
        }
      });
    });
    // }
  },
};
