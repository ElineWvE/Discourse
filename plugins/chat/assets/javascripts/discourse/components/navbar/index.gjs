import Component from "@glimmer/component";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { headerOffset } from "discourse/lib/offset-calculator";
import DiscourseURL from "discourse/lib/url";

export default class ChatNavbar extends Component {
  @service chatStateManager;

  @action
  async closeFullScreen() {
    this.chatStateManager.prefersDrawer();

    try {
      await DiscourseURL.routeTo(this.chatStateManager.lastKnownAppURL);
      await DiscourseURL.routeTo(this.chatStateManager.lastKnownChatURL);
    } catch (error) {
      await DiscourseURL.routeTo("/");
    }
  }

  <template>
    <div class="chat-navbar-container" style="top: {{(headerOffset)}}px">
      <nav class="chat-navbar">
        {{#if (has-block "current")}}
          <span class="chat-navbar__current">
            {{yield to="current"}}
          </span>
        {{/if}}

        <ul class="chat-navbar__right-actions">
          <li class="chat-navbar__right-action">
            <DButton
              @icon="discourse-compress"
              @title="chat.close_full_page"
              class="open-drawer-btn btn-flat"
              @action={{this.closeFullScreen}}
            />
          </li>
        </ul>
      </nav>
    </div>
  </template>
}
