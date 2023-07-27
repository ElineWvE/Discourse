import Component from "@glimmer/component";
import tracked from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";

export default class ConvertToPublicTopic extends Component {
  @service appEvents;

  @tracked publicCategoryId;
  @tracked saving = false;

  @action
  async makePublic() {
    try {
      this.saving = true;
      await this.args.model.topic.convertTopic("public", {
        categoryId: this.publicCategoryId,
      });
      this.args.model.topic.set("archetype", "regular");
      this.args.model.topic.set("category_id", this.publicCategoryId);
      this.appEvents.trigger("header:show-topic", topic);
      this.saving = false;
      this.args.closeModal();
    } catch (e) {
      this.flash = e;
      this.saving = false;
    }
  }
}
