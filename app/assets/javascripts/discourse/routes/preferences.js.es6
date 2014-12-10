import ShowFooter from "discourse/mixins/show-footer";
import RestrictedUserRoute from "discourse/routes/restricted-user";

export default RestrictedUserRoute.extend(ShowFooter, {
  model: function() {
    return this.modelFor('user');
  },

  setupController: function(controller, user) {
    controller.setProperties({ model: user, newNameInput: user.get('name') });
  },

  actions: {
    showAvatarSelector: function() {
      // all the properties needed for displaying the avatar selector modal
      var controller = this.controllerFor('avatar-selector');
      var user = this.modelFor('user');
      var props = user.getProperties(
        'username', 'email',
        'uploaded_avatar_id',
        'system_avatar_upload_id',
        'gravatar_avatar_upload_id',
        'custom_avatar_upload_id'
      );

      switch (props.uploaded_avatar_id) {
        case props.system_avatar_upload_id:
          props.selected = "system";
          break;
        case props.gravatar_avatar_upload_id:
          props.selected = "gravatar";
          break;
        case props.custom_avatar_upload_id:
          props.selected = "uploaded";
          break;
        default:
          props.selected = "system";
      }

      controller.setProperties(props);

      Discourse.Route.showModal(this, 'avatar-selector');
    },

    saveAvatarSelection: function() {
      var user = this.modelFor('user');
      var avatarSelector = this.controllerFor('avatar-selector');

      // sends the information to the server if it has changed
      if (avatarSelector.get('selectedUploadId') !== user.get('uploaded_avatar_id')) {
        user.pickAvatar(avatarSelector.get('selectedUploadId'));
      }

      // saves the data back
      user.setProperties(avatarSelector.getProperties(
        'system_avatar_upload_id',
        'gravatar_avatar_upload_id',
        'custom_avatar_upload_id'
      ));
      avatarSelector.send('closeModal');
    },

  }
});
