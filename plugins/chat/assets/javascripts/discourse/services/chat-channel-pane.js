import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Service, { inject as service } from "@ember/service";

export default class ChatChannelPane extends Service {
  @service appEvents;
  @service chat;
  @service chatChannelComposer;
  @service chatApi;
  @service chatComposerPresenceManager;

  @tracked reacting = false;
  @tracked selectingMessages = false;
  @tracked lastSelectedMessage = null;
  @tracked sending = false;

  get selectedMessageIds() {
    return this.chat.activeChannel?.selectedMessages?.mapBy("id") || [];
  }

  get composerService() {
    return this.chatChannelComposer;
  }

  get channel() {
    return this.chat.activeChannel;
  }

  @action
  cancelSelecting(selectedMessages) {
    this.selectingMessages = false;

    selectedMessages.forEach((message) => {
      message.selected = false;
    });
  }

  onSelectMessage(message) {
    this.lastSelectedMessage = message;
    this.selectingMessages = true;
  }

  @action
  editMessage(newContent, uploads) {
    this.sendingLoading = true;
    let data = {
      new_message: newContent,
      upload_ids: (uploads || []).map((upload) => upload.id),
    };
    return this.chatApi
      .editMessage(
        this.composerService.editingMessage.channelId,
        this.composerService.editingMessage.id,
        data
      )
      .then(() => {
        this.resetAfterSend();
      })
      .catch(popupAjaxError)
      .finally(() => {
        if (this._selfDeleted) {
          return;
        }
        this.sendingLoading = false;
      });
  }

  get lastCurrentUserMessage() {
    const lastCurrentUserMessage = this.chat.activeChannel.messages.findLast(
      (message) => message.user.id === this.currentUser.id
    );

    if (!lastCurrentUserMessage) {
      return;
    }

    if (lastCurrentUserMessage.staged || lastCurrentUserMessage.error) {
      return;
    }

    return lastCurrentUserMessage;
  }
}
