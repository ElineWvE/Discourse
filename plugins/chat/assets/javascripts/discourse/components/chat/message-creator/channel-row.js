import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import I18n from "I18n";

export default class ChatMessageCreatorChannelRow extends Component {
  @service site;

  get openChannelLabel() {
    return htmlSafe(I18n.t("chat.new_message_modal.open_channel"));
  }
}
