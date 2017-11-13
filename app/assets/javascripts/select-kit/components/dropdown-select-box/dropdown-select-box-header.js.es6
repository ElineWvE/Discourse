import SelectKitHeaderComponent from "select-kit/components/select-kit/select-kit-header";

export default SelectKitHeaderComponent.extend({
  layoutName: "select-kit/templates/components/dropdown-select-box/dropdown-select-box-header",
  classNames: "dropdown-select-box-header",

  name: Ember.computed.alias("computedContent.name"),
  icons: Ember.computed.alias("computedContent.icons")
});
