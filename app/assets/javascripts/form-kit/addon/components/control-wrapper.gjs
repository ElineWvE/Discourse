import Component from "@glimmer/component";
import { concat } from "@ember/helper";
import FKMeta from "form-kit/components/meta";
import FormText from "form-kit/components/text";
import concatClass from "discourse/helpers/concat-class";

export default class FKControlWrapper extends Component {
  get controlType() {
    switch (this.args.component.name) {
      case "FKControlInput":
        return "-input";
      case "FKControlText":
        return "-text";
      case "FKControlQuestion":
        return "-question";
      case "FKControlCode":
        return "-code";
      case "FKControlSelect":
        return "-select";
      case "FKControlIcon":
        return "-icon";
      case "FKControlImage":
        return "-image";
      case "FKControlMenu":
        return "-menu";
      case "FKControlRadioGroup":
        return "-radio-group";
    }
  }

  <template>
    <div
      class={{concatClass
        "form-kit__field"
        (concat "form-kit__field" this.controlType)
        (if @disabled "--disabled")
        (if @hasErrors "has-errors")
      }}
    >
      {{#if @title}}
        <label class="form-kit__field__title" for={{@fieldId}}>
          {{@title}}

          {{#unless @field.required}}
            <span class="form-kit__field__optional">(Optional)</span>
          {{/unless}}
        </label>
      {{/if}}

      {{#if @subtitle}}
        <FormText class="form-kit__field__subtitle">{{@subtitle}}</FormText>
      {{/if}}

      <div class={{concatClass "form-kit__field__content" @format}}>
        <@component
          @value={{@value}}
          @type={{@type}}
          @disabled={{@disabled}}
          @lang={{@lang}}
          @positiveLabel={{@positiveLabel}}
          @negativeLabel={{@negativeLabel}}
          @selection={{@selection}}
          @setValue={{@setValue}}
          @set={{@set}}
          @disabled={{@field.disabled}}
          @onSet={{@onSet}}
          @onUnset={{@onUnset}}
          @height={{@height}}
          @id={{@fieldId}}
          @name={{@name}}
          aria-invalid={{if @hasErrors "true"}}
          aria-describedby={{if @hasErrors @errorId}}
          ...attributes
          as |components|
        >
          {{yield components}}
        </@component>

        <FKMeta
          @hasErrors={{@hasErrors}}
          @description={{@description}}
          @value={{@value}}
          @field={{@field}}
          @errorId={{@errorId}}
          @errors={{@errors}}
        />
      </div>
    </div>
  </template>
}
