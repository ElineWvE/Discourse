import { tracked } from "@glimmer/tracking";
import { hash } from "@ember/helper";
import { and, not } from "truth-helpers";
import FieldInputDescription from "admin/components/schema-theme-setting/field-input-description";
import SchemaThemeSettingTypeModels from "admin/components/schema-theme-setting/types/models";
import CategorySelector from "select-kit/components/category-selector";

export default class SchemaThemeSettingTypeCategories extends SchemaThemeSettingTypeModels {
  @tracked
  value =
    this.args.value?.map((categoryId) => {
      return this.args.setting.metadata.categories[categoryId];
    }) || [];

  type = "categories";

  onChange(categories) {
    return categories.mapBy("id");
  }

  <template>
    <CategorySelector
      @categories={{this.value}}
      @onChange={{this.onInput}}
      @options={{hash allowUncategorized=false maximum=this.max}}
    />

    <div class="schema-field__input-supporting-text">
      {{#if (and @description (not this.validationErrorMessage))}}
        <FieldInputDescription @description={{@description}} />
      {{/if}}

      {{#if this.validationErrorMessage}}
        <div class="schema-field__input-error">
          {{this.validationErrorMessage}}
        </div>
      {{/if}}
    </div>
  </template>
}
