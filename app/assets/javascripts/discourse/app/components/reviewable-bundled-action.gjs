import Component from "@glimmer/component";
import { hash } from "@ember/helper";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { dasherize } from "@ember/string";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import { isRTL } from "discourse/lib/text-direction";
import DropdownSelectBox from "select-kit/components/dropdown-select-box";

export default class ReviewableBundledAction extends Component {
  @service site;

  get multiple() {
    return this.args.bundle.actions.length > 1;
  }

  get first() {
    return this.args.bundle.actions[0];
  }

  get placement() {
    const vertical = this.site.mobileView ? "top" : "bottom";
    const horizontal = isRTL() ? "end" : "start";

    return `${vertical}-${horizontal}`;
  }

  @action
  perform(id) {
    if (id) {
      const _action = this.args.bundle.actions.find((a) => a.id === id);
      this.args.performAction(_action);
    } else {
      this.args.performAction(this.first);
    }
  }

  <template>
    {{#if this.multiple}}
      <DropdownSelectBox
        @nameProperty="label"
        @content={{@bundle.actions}}
        @onChange={{this.perform}}
        @options={{hash
          showCaret=true
          disabled=@reviewableUpdating
          placement=this.placement
          translatedNone=@bundle.label
        }}
        class={{concatClass
          "reviewable-action-dropdown"
          "btn-icon-text"
          (dasherize this.first.id)
          this.first.button_class
        }}
      />
    {{else}}
      <DButton
        @action={{this.perform}}
        @translatedLabel={{this.first.label}}
        @disabled={{@reviewableUpdating}}
        class={{concatClass
          "btn-default reviewable-action"
          (dasherize this.first.id)
          this.first.button_class
        }}
      />
    {{/if}}
  </template>
}
