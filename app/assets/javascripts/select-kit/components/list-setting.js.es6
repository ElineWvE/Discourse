import MultiSelectComponent from "select-kit/components/multi-select";

export default MultiSelectComponent.extend({
  pluginApiIdentifiers: ["list-setting"],
  classNames: "list-setting",
  tokenSeparator: "|",
  settingValue: "",
  choices: null,
  filterable: true,

  init() {
    this._super();

    if (!Ember.isNone(this.get("settingName"))) {
      this.set("nameProperty", this.get("settingName"));
    }

    if (this.get("nameProperty").indexOf("color") > -1) {
      this.set("headerComponentOptions", Ember.Object.create({
        selectedNameComponent: "multi-select/selected-color"
      }));
    }
  },

  computeContent() {
    let content;
    if (Ember.isNone(this.get("choices"))) {
      content = this.get("settingValue").split(this.get("tokenSeparator"));;
    }  else {
      content = this.get("choices");
    }

    return Ember.makeArray(content).filter(c => !Ember.isEmpty(c));
  },

  mutateValues(values) {
    this.set("settingValue", values.join(this.get("tokenSeparator")));
  },

  computeValues() {
    return this.get("settingValue")
               .split(this.get("tokenSeparator"))
               .filter(c => !Ember.isEmpty(c));
  },

  didComputeAttributes() {
    if (Ember.isEmpty(this.get("computedContent"))) {
      this.setProperties({ rowComponent: null, noContentLabel: null });
    }
  },

  _handleTabOnKeyDown(event) {
    if (this.$highlightedRow().length === 1) {
      this._super(event);
    } else {
      this.close();
      return false;
    }
  }
});
