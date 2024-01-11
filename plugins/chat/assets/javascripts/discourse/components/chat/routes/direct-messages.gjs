import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import i18n from "discourse-common/helpers/i18n";
import Navbar from "discourse/plugins/chat/discourse/components/chat/navbar";
import ChannelsListDirect from "discourse/plugins/chat/discourse/components/channels-list-direct";

export default class ChatRoutesDirectMessages extends Component {
  @service site;

  <template>
    <div class="c-routes-direct-messages">
      <Navbar as |navbar|>
        <navbar.Title @title={{i18n "chat.direct_messages.title"}}/>
        <navbar.Actions as |action|>
          <action.NewDirectMessageButton />
        </navbar.Actions>
      </Navbar>

      <ChannelsListDirect />
    </div>
  </template>
}
