import Component from "@glimmer/component";
import DropdownSelectBox from "select-kit/components/dropdown-select-box";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import { dasherize } from "@ember/string";
import { hash } from "@ember/helper";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";
import { isRTL } from "discourse/lib/text-direction";

export default class ReviewableBundledAction extends Component {
  <template>
    {{#if this.multiple}}
      <DropdownSelectBox
        @class={{concatClass
          "reviewable-action-dropdown btn-icon-text"
          (dasherize this.first.id)
          this.first.button_class
        }}
        @nameProperty="label"
        @content={{@bundle.actions}}
        @onChange={{this.performById}}
        @options={{hash
          showCaret=true
          disabled=@reviewableUpdating
          placement=this.placement
          translatedNone=@bundle.label
        }}
      />
    {{else}}
      <DButton
        class={{concatClass
          "reviewable-action"
          (dasherize this.first.id)
          this.first.button_class
        }}
        @action={{this.performFirst}}
        @translatedLabel={{this.first.label}}
        @disabled={{@reviewableUpdating}}
      />
    {{/if}}
  </template>

  @service site;

  get multiple() {
    this.args.bundle.actions.length > 1;
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
  performById(id) {
    const _action = this.args.bundle.actions.find((a) => a.id === id);
    this.args.performAction(_action);
  }

  @action
  performFirst() {
    this.args.performAction(this.first);
  }
}
