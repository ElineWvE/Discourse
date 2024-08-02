import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import Service, { service } from "@ember/service";
import {
  confirmNotification,
  context,
} from "discourse/lib/desktop-notifications";
import { disableImplicitInjections } from "discourse/lib/implicit-injections";
import KeyValueStore from "discourse/lib/key-value-store";
import {
  isPushNotificationsSupported,
  keyValueStore as pushNotificationKeyValueStore,
  subscribe as subscribePushNotification,
  unsubscribe as unsubscribePushNotification,
  userSubscriptionKey as pushNotificationUserSubscriptionKey,
} from "discourse/lib/push-notifications";

const keyValueStore = new KeyValueStore(context);
const DISABLED = "disabled";
const ENABLED = "enabled";
const SUBSCRIBED = "subscribed";

@disableImplicitInjections
export default class DesktopNotificationsService extends Service {
  @service currentUser;
  @service site;
  @service siteSettings;

  @tracked isEnabledBrowser;
  @tracked isEnabledPush;

  constructor() {
    super(...arguments);

    if (!this.currentUser) {
      this.isEnabledPush = false;
      this.isEnabledBrowser = false;

      return;
    }

    this.isEnabledBrowser = this.isGrantedPermission
      ? keyValueStore.getItem("notifications-disabled") === ENABLED
      : false;
    this.isEnabledPush =
      pushNotificationKeyValueStore.getItem(
        pushNotificationUserSubscriptionKey(this.currentUser)
      ) === SUBSCRIBED;
  }

  get isNotSupported() {
    return typeof window.Notification === "undefined";
  }

  get notificationsPermission() {
    return this.isNotSupported ? "" : Notification.permission;
  }

  get isDeniedPermission() {
    if (this.isNotSupported) {
      return false;
    }

    return this.notificationsPermission === "denied";
  }

  get isGrantedPermission() {
    if (this.isNotSupported) {
      return false;
    }

    return this.notificationsPermission === "granted";
  }

  get isEnabled() {
    return this.isEnabledPush || this.isEnabledBrowser;
  }

  get isSubscribed() {
    if (!this.isEnabled) {
      return false;
    }

    return this.isPushNotificationsPreferred
      ? this.isEnabledPush
      : this.isEnabledBrowser;
  }

  get isPushNotificationsPreferred() {
    return (
      (this.site.mobileView ||
        this.siteSettings.enable_desktop_push_notifications) &&
      isPushNotificationsSupported()
    );
  }

  setIsEnabledBrowser(value) {
    const status = value ? ENABLED : DISABLED;
    keyValueStore.setItem("notifications-disabled", status);
    this.isEnabledBrowser = value;
  }

  setIsEnabledPush(value) {
    const user = this.currentUser;
    const status = value ? SUBSCRIBED : value;

    if (!user) {
      return false;
    }

    pushNotificationKeyValueStore.setItem(
      pushNotificationUserSubscriptionKey(user),
      status
    );

    this.isEnabledPush = value;
  }

  @action
  async disable() {
    if (this.isEnabledBrowser) {
      this.setIsEnabledBrowser(false);
    }
    if (this.isEnabledPush) {
      await unsubscribePushNotification(this.currentUser, () => {
        this.setIsEnabledPush(false);
      });
    }

    return true;
  }

  @action
  async enable() {
    if (this.isPushNotificationsPreferred) {
      await subscribePushNotification(() => {
        this.setIsEnabledPush(true);
      }, this.siteSettings.vapid_public_key_bytes);

      return true;
    } else {
      this.setIsEnabledBrowser(true);
      await Notification.requestPermission((permission) => {
        confirmNotification(this.siteSettings);
        return permission === "granted";
      });
    }
  }
}
