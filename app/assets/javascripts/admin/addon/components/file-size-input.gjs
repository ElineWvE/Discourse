import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import TextField from "discourse/components/text-field";
import I18n from "discourse-i18n";
import ComboBox from "select-kit/components/combo-box";

const ALLOWED_KEYS = [
  "Enter",
  "Backspace",
  "Tab",
  "Delete",
  "ArrowLeft",
  "ArrowUp",
  "ArrowRight",
  "ArrowDown",
  "0",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
];

export default class FileSizeInput extends Component {
  @tracked fileSizeUnit;
  @tracked sizeValue;
  @tracked pendingSizeValue;
  @tracked pendingFileSizeUnit;

  constructor(owner, args) {
    super(owner, args);
    this.originalSizeKB = this.args.sizeValueKB;
    this.sizeValue = this.args.sizeValueKB;

    this._defaultUnit();
  }

  _defaultUnit() {
    this.fileSizeUnit = "kb";
    if (this.originalSizeKB <= 1024) {
      this.onFileSizeUnitChange("kb");
    }
    if (this.originalSizeKB > 1024 && this.originalSizeKB <= 1024 * 1024) {
      this.onFileSizeUnitChange("mb");
    }
    if (this.originalSizeKB > 1024 * 1024) {
      this.onFileSizeUnitChange("gb");
    }
  }

  @action
  keyDown(event) {
    if (!ALLOWED_KEYS.includes(event.key)) {
      event.preventDefault();
    }
  }

  get dropdownOptions() {
    return [
      { label: I18n.t("number.human.storage_units.units.kb"), value: "kb" },
      { label: I18n.t("number.human.storage_units.units.mb"), value: "mb" },
      { label: I18n.t("number.human.storage_units.units.gb"), value: "gb" },
    ];
  }

  @action
  handleFileSizeChange(value) {
    if (value !== "") {
      this.pendingSizeValue = value;
      this._onFileSizeChange(value);
    }
  }

  _onFileSizeChange(newSize) {
    let fileSizeKB;
    switch (this.fileSizeUnit) {
      case "kb":
        fileSizeKB = newSize;
        break;
      case "mb":
        fileSizeKB = newSize * 1024;
        break;
      case "gb":
        fileSizeKB = newSize * 1024 * 1024;
        break;
    }
    if (fileSizeKB > this.args.max) {
      this.args.updateValidationMessage(
        I18n.toHumanSize(fileSizeKB * 1024) +
          " " +
          I18n.t("file_size_input.error.size_too_large") +
          " " +
          I18n.toHumanSize(this.args.max * 1024)
      );
      // Removes the green save checkmark button
      this.args.onChangeSize(this.originalSizeKB);
    } else {
      this.args.onChangeSize(fileSizeKB);
      this.args.updateValidationMessage(null);
    }
  }

  @action
  onFileSizeUnitChange(newUnit) {
    if (this.fileSizeUnit === "kb" && newUnit === "mb") {
      this.pendingSizeValue = this.sizeValue / 1024;
    }
    if (this.fileSizeUnit === "kb" && newUnit === "gb") {
      this.pendingSizeValue = this.sizeValue / 1024 / 1024;
    }
    if (this.fileSizeUnit === "mb" && newUnit === "kb") {
      this.pendingSizeValue = this.sizeValue * 1024;
    }
    if (this.fileSizeUnit === "mb" && newUnit === "gb") {
      this.pendingSizeValue = this.sizeValue / 1024;
    }
    if (this.fileSizeUnit === "gb" && newUnit === "mb") {
      this.pendingSizeValue = this.sizeValue * 1024;
    }
    if (this.fileSizeUnit === "gb" && newUnit === "kb") {
      this.pendingSizeValue = this.sizeValue * 1024 * 1024;
    }
    this.pendingFileSizeUnit = newUnit;
  }

  @action
  applySizeValueChanges() {
    this.sizeValue = this.pendingSizeValue;
  }

  @action
  applyUnitChanges() {
    this.fileSizeUnit = this.pendingFileSizeUnit;
  }

  <template>
    <div class="file-size-picker">
      <TextField
        @class="file-size-input"
        @value={{this.sizeValue}}
        @onChange={{this.handleFileSizeChange}}
        {{on "keydown" this.keyDown}}
        {{didInsert this.applySizeValueChanges}}
        {{didUpdate this.applySizeValueChanges this.pendingSizeValue}}
      />
      <ComboBox
        @class="file-size-unit-selector"
        @valueProperty="value"
        @content={{this.dropdownOptions}}
        @value={{this.fileSizeUnit}}
        @onChange={{this.onFileSizeUnitChange}}
        {{didInsert this.applyUnitChanges}}
        {{didUpdate this.applyUnitChanges this.pendingFileSizeUnit}}
      />
    </div>
  </template>
}
