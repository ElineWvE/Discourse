import { createWidgetFrom } from "discourse/widgets/widget";
import { DefaultNotificationItem } from "discourse/widgets/default-notification-item";
import { formatUsername } from "discourse/lib/utilities";

createWidgetFrom(
  DefaultNotificationItem,
  "bookmark-reminder-notification-item",
  {
    text(notificationName, data) {
      const username = formatUsername(data.display_username);
      const description = this.description(data);

      return I18n.t("notifications.bookmark_reminder", {
        description,
        username
      });
    }
  }
);
