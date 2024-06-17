import { click, fillIn, triggerEvent } from "@ember/test-helpers";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import { query } from "discourse/tests/helpers/qunit-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";

class Field {
  constructor(selector) {
    if (selector instanceof HTMLElement) {
      this.element = selector;
    } else {
      this.element = query(selector);
    }
  }

  async fillIn(value) {
    let element;

    switch (this.element.dataset.controlType) {
      case "input":
        element = this.element.querySelector("input");
        break;
      case "code":
        element = this.element.querySelector("textarea");
        break;
      case "text":
        element = this.element.querySelector("textarea");
        break;
    }

    await fillIn(element, value);
  }

  async toggle() {
    await click(this.element.querySelector("input"));
  }

  async select(value) {
    switch (this.element.dataset.controlType) {
      case "icon":
        const picker = selectKit(
          "#" + this.element.querySelector("details").id
        );
        await picker.expand();
        await picker.selectRowByValue(value);
        break;
      case "select":
        const select = this.element.querySelector("select");
        select.value = value;
        await triggerEvent(select, "input");
        break;
      case "menu":
        const trigger = this.element.querySelector(
          ".fk-d-menu__trigger.form-kit__control-menu"
        );
        await click(trigger);
        const menu = document.body.querySelector(
          `[aria-labelledby="${trigger.id}"`
        );
        const item = menu.querySelector(
          `.form-kit__control-menu-item[data-value="${value}"] .btn`
        );
        await click(item);
        break;
      case "radio-group":
        const radio = this.element.querySelector(
          `input[type="radio"][value="${value}"]`
        );
        await click(radio);
        break;
      default:
        throw new Error("Unsupported field type");
    }
  }
}

class Form {
  constructor(selector) {
    if (selector instanceof HTMLElement) {
      this.element = selector;
    } else {
      this.element = query(selector);
    }
  }

  field(name) {
    const field = new Field(
      this.element.querySelector(`[data-name="${name}"]`)
    );

    if (!field) {
      throw new Error(`Field with name ${name} not found`);
    }

    return field;
  }
}
export default function form(selector) {
  const helper = new Form(selector);

  return {
    field(name) {
      return helper.field(name);
    },
  };
}