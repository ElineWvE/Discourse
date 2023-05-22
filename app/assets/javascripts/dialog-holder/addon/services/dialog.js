import Service from "@ember/service";
import A11yDialog from "a11y-dialog";
import { bind } from "discourse-common/utils/decorators";

export default Service.extend({
  dialogInstance: null,
  message: null,
  title: null,
  titleElementId: null,
  type: null,

  bodyComponent: null,
  bodyComponentModel: null,

  confirmButtonIcon: null,
  confirmButtonLabel: null,
  confirmButtonClass: null,
  confirmButtonDisabled: false,
  cancelButtonLabel: null,
  cancelButtonClass: null,
  shouldDisplayCancel: null,

  didConfirm: null,
  didCancel: null,
  buttons: null,
  class: null,
  _confirming: false,

  dialog(params) {
    const {
      message,
      bodyComponent,
      bodyComponentModel,
      type,
      title,

      confirmButtonClass = "btn-primary",
      confirmButtonIcon,
      confirmButtonLabel = "ok_value",
      confirmButtonDisabled = false,

      cancelButtonClass = "btn-default",
      cancelButtonLabel = "cancel_value",
      shouldDisplayCancel,

      didConfirm,
      didCancel,
      buttons
    } = params;

    const element = document.getElementById("dialog-holder");

    this.setProperties({
      message,
      bodyComponent,
      bodyComponentModel,
      type,
      dialogInstance: new A11yDialog(element),

      title,
      titleElementId: title !== null ? "dialog-title" : null,

      confirmButtonClass,
      confirmButtonDisabled,
      confirmButtonIcon,
      confirmButtonLabel,

      cancelButtonClass,
      cancelButtonLabel,
      shouldDisplayCancel,

      didConfirm,
      didCancel,
      buttons,
      class: params.class
    });

    this.dialogInstance.show();

    this.dialogInstance.on("hide", () => {
      if (!this._confirming && this.didCancel) {
        this.didCancel();
      }

      this.reset();
    });
  },

  alert(params) {
    // support string param for easier porting of bootbox.alert
    if (typeof params === "string") {
      return this.dialog({
        message: params,
        type: "alert"
      });
    }

    return this.dialog({
      ...params,
      type: "alert"
    });
  },

  confirm(params) {
    return this.dialog({
      ...params,
      shouldDisplayCancel: true,
      buttons: null,
      type: "confirm"
    });
  },

  notice(params) {
    // support string param for easier porting of bootbox.alert
    if (typeof params === "string") {
      return this.dialog({
        message: params,
        type: "notice"
      });
    }

    return this.dialog({
      ...params,
      type: "notice"
    });
  },

  yesNoConfirm(params) {
    return this.confirm({
      ...params,
      confirmButtonLabel: "yes_value",
      cancelButtonLabel: "no_value"
    });
  },

  deleteConfirm(params) {
    return this.confirm({
      ...params,
      confirmButtonClass: "btn-danger",
      confirmButtonLabel: params.confirmButtonLabel || "delete"
    });
  },

  reset() {
    this.setProperties({
      message: null,
      bodyComponent: null,
      bodyComponentModel: null,
      type: null,
      dialogInstance: null,

      title: null,
      titleElementId: null,

      confirmButtonDisabled: false,
      confirmButtonIcon: null,
      confirmButtonLabel: null,

      cancelButtonClass: null,
      cancelButtonLabel: null,
      shouldDisplayCancel: null,

      didConfirm: null,
      didCancel: null,
      buttons: null,
      class: null,

      _confirming: false
    });
  },

  willDestroy() {
    this.dialogInstance?.destroy();
    this.reset();
  },

  @bind
  didConfirmWrapped() {
    if (this.didConfirm) {
      this.didConfirm();
    }
    this._confirming = true;
    this.dialogInstance.hide();
  },

  @bind
  cancel() {
    this.dialogInstance.hide();
  },

  @bind
  enableConfirmButton() {
    this.set("confirmButtonDisabled", false);
  }
});
