import Controller from "@ember/controller";
import { action } from "@ember/object";
import { equal } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";
import { extractError } from "discourse/lib/ajax-error";
import { bufferedProperty } from "discourse/mixins/buffered-content";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import Group from "discourse/models/group";
import Invite from "discourse/models/invite";

export default Controller.extend(
  ModalFunctionality,
  bufferedProperty("invite"),
  {
    allGroups: null,

    invite: null,
    invites: null,

    autogenerated: false,
    showAdvanced: false,

    type: "link",

    onShow() {
      Group.findAll().then((groups) => {
        this.set("allGroups", groups.filterBy("automatic", false));
      });

      this.setProperties({
        autogenerated: false,
        showAdvanced: false,
      });

      this.setInvite(Invite.create());
    },

    onClose() {
      if (this.autogenerated) {
        this.invite
          .destroy()
          .then(() => this.invites.removeObject(this.invite));
      }
    },

    setInvite(invite) {
      this.setProperties({
        invite,
        type: invite.email ? "email" : "link",
      });
    },

    save(opts) {
      const newRecord =
        (this.autogenerated || !this.invite.id) && !opts.autogenerated;

      this.set("autogenerated", opts.autogenerated);

      const data = { ...this.buffered.buffer };

      if (data.groupIds !== undefined) {
        data.group_ids = data.groupIds;
        delete data.groupIds;
      }

      if (data.topicId !== undefined) {
        data.topic_id = data.topicId;
        delete data.topicId;
        delete data.topicTitle;
      }

      if (this.type === "link") {
        if (this.buffered.get("email")) {
          data.email = "";
          data.custom_message = "";
        }
      } else if (this.type === "email") {
        if (this.buffered.get("max_redemptions_allowed") > 1) {
          data.max_redemptions_allowed = 1;
        }

        if (opts.sendEmail) {
          data.send_email = true;
        }
      }

      return this.invite
        .save(data)
        .then(() => {
          this.rollbackBuffer();

          if (newRecord) {
            this.invites.unshiftObject(this.invite);
          }

          if (!this.autogenerated) {
            this.send("closeModal");
          }
        })
        .catch((e) =>
          this.appEvents.trigger("modal-body:flash", {
            text: extractError(e),
            messageClass: "error",
          })
        );
    },

    isLink: equal("type", "link"),
    isEmail: equal("type", "email"),

    @discourseComputed(
      "currentUser.staff",
      "siteSettings.invite_link_max_redemptions_limit",
      "siteSettings.invite_link_max_redemptions_limit_users"
    )
    maxRedemptionsAllowedLimit(staff, staffLimit, usersLimit) {
      return staff ? staffLimit : usersLimit;
    },

    @discourseComputed("buffered.expires_at")
    expiresAtRelative(expires_at) {
      return moment.duration(moment(expires_at) - moment()).humanize();
    },

    @discourseComputed("type", "buffered.email")
    disabled(type, email) {
      if (type === "email") {
        return !email;
      }

      return false;
    },

    @discourseComputed("type", "invite.email", "buffered.email")
    newEmail(type, email, bufferedEmail) {
      return type === "email" && (!email || email !== bufferedEmail);
    },

    @action
    saveInvite(sendEmail) {
      this.appEvents.trigger("modal-body:clearFlash");

      this.save({ sendEmail });
    },
  }
);
