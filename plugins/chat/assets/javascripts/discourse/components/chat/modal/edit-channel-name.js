import Component from "@glimmer/component";
import discourseDebounce from "discourse-common/lib/debounce";
import { ajax } from "discourse/lib/ajax";
import { cancel } from "@ember/runloop";
import { action } from "@ember/object";
import { extractError } from "discourse/lib/ajax-error";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";

const SLUG_MAX_LENGTH = 100;

export default class ChatModalEditChannelName extends Component {
  @service chatApi;
  @service siteSettings;

  @tracked editedName = this.channel.title;
  @tracked editedSlug = this.channel.slug;
  @tracked autoGeneratedSlug = "";
  @tracked flash;

  #generateSlugHandler = null;

  get channel() {
    return this.args.model;
  }

  get isSaveDisabled() {
    return (
      (this.channel.title === this.editedName &&
        this.channel.slug === this.editedSlug) ||
      this.editedName?.length > this.siteSettings.max_topic_title_length ||
      this.editedSlug?.length > SLUG_MAX_LENGTH
    );
  }

  @action
  onSave() {
    return this.chatApi
      .updateChannel(this.channel.id, {
        name: this.editedName,
        slug: this.editedSlug || this.autoGeneratedSlug || this.channel.slug,
      })
      .then((result) => {
        this.channel.title = result.channel.title;
        this.args.closeModal();
      })
      .catch((error) => (this.flash = extractError(error)));
  }

  @action
  onChangeChatChannelName(title) {
    this.flash = null;
    this.#debouncedGenerateSlug(title);
  }

  @action
  onChangeChatChannelSlug() {
    this.flash = null;
    this.#debouncedGenerateSlug(this.editedName);
  }

  #debouncedGenerateSlug(name) {
    cancel(this.#generateSlugHandler);
    this.autoGeneratedSlug = "";

    if (!name) {
      return;
    }

    this.#generateSlugHandler = discourseDebounce(
      this,
      this.#generateSlug,
      name,
      300
    );
  }

  // intentionally not showing AJAX error for this, we will autogenerate
  // the slug server-side if they leave it blank
  #generateSlug(name) {
    return ajax("/slugs.json", { type: "POST", data: { name } }).then(
      (response) => {
        this.autoGeneratedSlug = response.slug;
      }
    );
  }
}
