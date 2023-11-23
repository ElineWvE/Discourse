import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import DButton from "discourse/components/d-button";
import i18n from "discourse-common/helpers/i18n";
import eq from "truth-helpers/helpers/eq";

export default class extends Component {
  <template>
    {{#if @message.error}}
      <div class="chat-message-error">
        {{#if (eq @message.error "network_error")}}
          <DButton
            class="chat-message-error__retry-btn"
            @action={{fn @onRetry @message}}
            @icon="exclamation-circle"
          >
            <span class="chat-message-error__retry-btn-title">
              {{i18n "chat.retry_staged_message.title"}}
            </span>
            <span class="chat-message-error__retry-btn-action">
              {{i18n "chat.retry_staged_message.action"}}
            </span>
          </DButton>
        {{else}}
          {{@message.error}}
        {{/if}}
      </div>
    {{/if}}
  </template>
}
