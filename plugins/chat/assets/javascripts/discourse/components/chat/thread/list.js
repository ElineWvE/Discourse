import Component from "@glimmer/component";
import { inject as service } from "@ember/service";

export default class ChatThreadList extends Component {
  @service chat;

  get channel() {
    return this.chat.activeChannel;
  }
}
