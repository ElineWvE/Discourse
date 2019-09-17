import { SECOND_FACTOR_METHODS } from "discourse/models/user";

export default Ember.Component.extend({
  actions: {
    authenticateSecurityKey() {
      this.attrs["action"]();
    },
    useAnotherMethod() {
      this.set("showSecurityKey", false);
      this.set("showSecondFactor", true);
      this.set("secondFactorMethod", SECOND_FACTOR_METHODS.TOTP);
    }
  }
});
