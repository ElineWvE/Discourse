import Component from "@glimmer/component";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import I18n from "I18n";
import { alias } from "@ember/object/computed";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";
import { FORMAT } from "select-kit/components/future-date-input-selector";
import TopicTimer from "discourse/models/topic-timer";

export const CLOSE_STATUS_TYPE = "close";
export const CLOSE_AFTER_LAST_POST_STATUS_TYPE = "close_after_last_post";
export const OPEN_STATUS_TYPE = "open";
export const PUBLISH_TO_CATEGORY_STATUS_TYPE = "publish_to_category";
export const DELETE_STATUS_TYPE = "delete";
export const BUMP_TYPE = "bump";
export const DELETE_REPLIES_TYPE = "delete_replies";

export default class EditTopicTimer extends Component {
  @service currentUser;

  @tracked loading = false;
  @tracked isPublic = "true";
  @tracked defaultStatusType = this.publicTimerTypes[0].id;
  @tracked flash;

  get publicTimerTypes() {
    const types = [];
    const { closed, category, isPrivateMessage, invisible } =
      this.args.model.topic;

    if (!closed) {
      types.push({
        id: CLOSE_STATUS_TYPE,
        name: I18n.t("topic.auto_close.title"),
      });
      types.push({
        id: CLOSE_AFTER_LAST_POST_STATUS_TYPE,
        name: I18n.t("topic.auto_close_after_last_post.title"),
      });
    }

    if (closed) {
      types.push({
        id: OPEN_STATUS_TYPE,
        name: I18n.t("topic.auto_reopen.title"),
      });
    }

    if (this.args.model.topic.details.can_delete) {
      types.push({
        id: DELETE_STATUS_TYPE,
        name: I18n.t("topic.auto_delete.title"),
      });
    }

    types.push({
      id: BUMP_TYPE,
      name: I18n.t("topic.auto_bump.title"),
    });

    if (this.args.model.topic.details.can_delete) {
      types.push({
        id: DELETE_REPLIES_TYPE,
        name: I18n.t("topic.auto_delete_replies.title"),
      });
    }

    if (closed) {
      types.push({
        id: CLOSE_STATUS_TYPE,
        name: I18n.t("topic.temp_open.title"),
      });
    }

    if (!closed) {
      types.push({
        id: OPEN_STATUS_TYPE,
        name: I18n.t("topic.temp_close.title"),
      });
    }

    if (
      (category && category.read_restricted) ||
      isPrivateMessage ||
      invisible
    ) {
      types.push({
        id: PUBLISH_TO_CATEGORY_STATUS_TYPE,
        name: I18n.t("topic.publish_to_category.title"),
      });
    }

    return types;
  }

  _setTimer(time, durationMinutes, statusType, basedOnLastPost, categoryId) {
    this.loading = true;

    TopicTimer.update(
      this.args.model.topic.id,
      time,
      basedOnLastPost,
      statusType,
      categoryId,
      durationMinutes
    )
      .then((result) => {
        if (time || durationMinutes) {
          this.closeModal();

          this.args.model.topic.topicTimer.execute_at = result.execute_at;
          this.args.model.topic.topicTimer.duration_minutes =
            result.duration_minutes;
          this.args.model.topic.topicTimer.category_id = result.category_id;

          this.args.model.topic.closed = result.closed;
        } else {
          this.args.model.topic.topic_timer = TopicTimer.create({
            status_type: this.defaultStatusType,
          });
          this.send("onChangeInput", null, null);
        }
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.loading = false;
      });
  }

  @action
  onChangeStatusType(value) {
    this.args.model.topic.topicTimer.based_on_last_post =
      CLOSE_AFTER_LAST_POST_STATUS_TYPE === value;
    this.args.model.topic.topicTimer.status_type = value;
  }

  @action
  onChangeInput(_type, time) {
    if (moment.isMoment(time)) {
      time = time.format(FORMAT);
    }
    this.args.model.topic.topicTimer.updateTime = time;
  }

  @action
  async saveTimer() {
    if (
      !this.args.model.topic.topicTimer.updateTime &&
      !this.args.model.topic.topicTimer.duration_minutes
    ) {
      this.flash = I18n.t("topic.topic_status_update.time_frame_required");
      return;
    }

    if (
      this.args.model.topic.topicTimer.duration_minutes &&
      !this.args.model.topic.topicTimer.updateTime
    ) {
      if (this.args.model.topic.topicTimer.duration_minutes <= 0) {
        this.flash = I18n.t("topic.topic_status_update.min_duration");
        return;
      }

      // cannot be more than 20 years
      if (this.args.model.topic.topicTimer.duration_minutes > 20 * 365 * 1440) {
        this.flash = I18n.t("topic.topic_status_update.max_duration");
        return;
      }
    }

    let statusType = this.args.model.topic.topicTimer.status_type;
    if (statusType === CLOSE_AFTER_LAST_POST_STATUS_TYPE) {
      statusType = CLOSE_STATUS_TYPE;
    }

    await this._setTimer(
      this.args.model.topic.topicTimer.updateTime,
      this.args.model.topic.topicTimer.duration_minutes,
      statusType,
      this.args.model.topic.topicTimer.based_on_last_post,
      this.args.model.topic.topicTimer.category_id
    );
  }

  @action
  async removeTimer() {
    let statusType = this.args.model.topic.topicTimer.status_type;
    if (statusType === CLOSE_AFTER_LAST_POST_STATUS_TYPE) {
      statusType = CLOSE_STATUS_TYPE;
    }
    await this._setTimer(null, null, statusType);
  }
}
