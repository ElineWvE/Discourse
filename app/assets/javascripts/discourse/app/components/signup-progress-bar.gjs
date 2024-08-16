import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { eq } from "truth-helpers";
import concatClass from "discourse/helpers/concat-class";
import dIcon from "discourse-common/helpers/d-icon";
import I18n from "discourse-i18n";

export default class SignupProgressBar extends Component {
  @service siteSettings;
  @tracked steps = [];

  constructor() {
    super(...arguments);
    if (this.siteSettings.must_approve_users) {
      this.steps = ["signup", "activate", "approve", "login"];
    } else {
      this.steps = ["signup", "activate", "login"];
    }
  }

  stepText(step) {
    return I18n.t(`create_account.progress_bar.${step}`);
  }

  get currentStepIndex() {
    return this.steps.findIndex((step) => step === this.args.step);
  }

  get lastStepIndex() {
    return this.steps.length - 1;
  }

  @action
  getStepState(index) {
    if (index === this.currentStepIndex) {
      return "active";
    } else if (index < this.currentStepIndex) {
      return "completed";
    } else if (index > this.currentStepIndex) {
      return "incomplete";
    }
  }

  <template>
    {{#if @step}}
      <div class="signup-progress-bar">
        {{#each this.steps as |step index|}}
          <div class={{concatClass "step" (this.getStepState index)}}>
            <div class="circle">
              {{#if (eq (this.getStepState index) "completed")}}
                {{dIcon "check"}}
              {{/if}}
            </div>
            <span>
              {{this.stepText step}}
            </span>
          </div>
          {{#unless (eq index this.lastStepIndex)}}
            <span class={{concatClass "line" (this.getStepState index)}}></span>
          {{/unless}}
        {{/each}}
      </div>
    {{/if}}
  </template>
}
