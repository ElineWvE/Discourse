import Component from "@ember/component";
import UppyUploadMixin from "discourse/mixins/uppy-upload";
import { tracked } from "@glimmer/tracking";
import { dasherize } from "@ember/string";

export default class FormTemplateFieldUpload extends Component.extend(
  UppyUploadMixin
) {
  @tracked uploadValue;
  @tracked fileUploadElementId = `${dasherize(this.attributes.label)}-uploader`;
  @tracked fileInputSelector = `#${this.fileUploadElementId}`;
  type = "jpg";

  uploadDone(upload) {
    const uploadMarkdown = `![${upload.file_name}|${upload.width}x${upload.height}](${upload.short_url})`;

    if (this.uploadValue && this.allowMultipleFiles) {
      this.uploadValue = `${this.uploadValue}\n${uploadMarkdown}`;
    } else {
      this.uploadValue = uploadMarkdown;
    }
  }
}
