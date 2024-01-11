import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import i18n from "discourse-common/helpers/i18n";
import Navbar from "discourse/plugins/chat/discourse/components/chat/navbar";
import ChannelsListPublic from "discourse/plugins/chat/discourse/components/channels-list-public";

export default class ChatRoutesChannels extends Component {
  @service site;

  <template>
    <div class="c-routes-channels">
      <Navbar as |navbar|>
        <navbar.Title @title={{i18n "chat.chat_channels"}} />
        <navbar.Actions as |action|>
          <action.BrowseChannelsButton />
        </navbar.Actions>
      </Navbar>

      <ChannelsListPublic />
    </div>
  </template>
}
