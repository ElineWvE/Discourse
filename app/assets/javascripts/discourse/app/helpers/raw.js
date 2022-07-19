import { helperContext, registerUnbound } from "discourse-common/lib/helpers";
import { findRawTemplate } from "discourse-common/lib/raw-templates";
import { htmlSafe } from "@ember/template";
import { RUNTIME_OPTIONS } from "discourse-common/lib/raw-handlebars-helpers";
import { getOwner, setOwner } from "@ember/application";

function renderRaw(ctx, template, templateName, params) {
  params = Object.assign({}, params);
  params.parent = params.parent || ctx;

  let context = helperContext();
  if (!params.view) {
    const viewClass = context.registry.resolve(`raw-view:${templateName}`);

    if (viewClass) {
      params.view = viewClass.create(params, context);
      setOwner(params.view, getOwner(context.site));
    }

    if (!params.view) {
      params = Object.assign({}, params, context);
    }
  }

  return htmlSafe(template(params, RUNTIME_OPTIONS));
}

registerUnbound("raw", function (templateName, params) {
  templateName = templateName.replace(".", "/");

  const template = findRawTemplate(templateName);
  if (!template) {
    // eslint-disable-next-line no-console
    console.warn("Could not find raw template: " + templateName);
    return;
  }
  return renderRaw(this, template, templateName, params);
});
