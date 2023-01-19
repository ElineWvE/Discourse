import { escapeExpression } from "discourse/lib/utilities";
import { ajax } from "discourse/lib/ajax";
import { cancel } from "@ember/runloop";
import discourseDebounce from "discourse-common/lib/debounce";
import Controller from "@ember/controller";
import I18n from "I18n";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { action, computed } from "@ember/object";
import { gt, notEmpty } from "@ember/object/computed";
import { inject as service } from "@ember/service";
import { isBlank, isPresent } from "@ember/utils";
import { htmlSafe } from "@ember/template";

const DEFAULT_HINT = htmlSafe(
  I18n.t("chat.create_channel.choose_category.default_hint", {
    link: "/categories",
    category: "category",
  })
);

export default class CreateChannelController extends Controller.extend(
  ModalFunctionality
) {
  @service chat;
  @service dialog;
  @service chatChannelsManager;
  @service chatApi;

  category = null;
  categoryId = null;
  name = "";
  slug = "";
  autoGeneratedSlug = "";
  description = "";
  categoryPermissionsHint = null;
  autoJoinUsers = null;
  autoJoinWarning = "";

  @notEmpty("category") categorySelected;
  @gt("siteSettings.max_chat_auto_joined_users", 0) autoJoinAvailable;

  @computed("categorySelected", "name")
  get createDisabled() {
    return !this.categorySelected || isBlank(this.name);
  }

  @computed("categorySelected", "name")
  get categoryName() {
    return this.categorySelected && isPresent(this.name)
      ? escapeExpression(this.name)
      : null;
  }

  onShow() {
    this.set("categoryPermissionsHint", DEFAULT_HINT);
  }

  onClose() {
    cancel(this.generateSlugHandler);
    this.setProperties({
      categoryId: null,
      category: null,
      name: "",
      description: "",
      slug: "",
      autoGeneratedSlug: "",
      categoryPermissionsHint: DEFAULT_HINT,
      autoJoinWarning: "",
    });
  }

  _createChannel() {
    const data = {
      chatable_id: this.categoryId,
      name: this.name,
      slug: this.slug || this.autoGeneratedSlug,
      description: this.description,
      auto_join_users: this.autoJoinUsers,
    };

    return this.chatApi
      .createChannel(data)
      .then((channel) => {
        this.send("closeModal");
        this.chatChannelsManager.follow(channel);
        this.chat.openChannel(channel);
      })
      .catch((e) => {
        this.flash(e.jqXHR.responseJSON.errors[0], "error");
      });
  }

  _buildCategorySlug(category) {
    const parent = category.parentCategory;

    if (parent) {
      return `${this._buildCategorySlug(parent)}/${category.slug}`;
    } else {
      return category.slug;
    }
  }

  _updateAutoJoinConfirmWarning(category, catPermissions) {
    const allowedGroups = catPermissions.allowed_groups;

    if (catPermissions.private) {
      const warningTranslationKey =
        allowedGroups.length < 3 ? "warning_groups" : "warning_multiple_groups";

      this.set(
        "autoJoinWarning",
        I18n.t(`chat.create_channel.auto_join_users.${warningTranslationKey}`, {
          members_count: catPermissions.members_count,
          group: escapeExpression(allowedGroups[0]),
          group_2: escapeExpression(allowedGroups[1]),
          count: allowedGroups.length,
        })
      );
    } else {
      this.set(
        "autoJoinWarning",
        I18n.t(`chat.create_channel.auto_join_users.public_category_warning`, {
          category: escapeExpression(category.name),
        })
      );
    }
  }

  _updatePermissionsHint(category) {
    if (category) {
      const fullSlug = this._buildCategorySlug(category);

      return this.chatApi
        .categoryPermissions(category.id)
        .then((catPermissions) => {
          this._updateAutoJoinConfirmWarning(category, catPermissions);
          const allowedGroups = catPermissions.allowed_groups;
          const translationKey =
            allowedGroups.length < 3 ? "hint_groups" : "hint_multiple_groups";

          this.set(
            "categoryPermissionsHint",
            htmlSafe(
              I18n.t(`chat.create_channel.choose_category.${translationKey}`, {
                link: `/c/${escapeExpression(fullSlug)}/edit/security`,
                hint: escapeExpression(allowedGroups[0]),
                hint_2: escapeExpression(allowedGroups[1]),
                count: allowedGroups.length,
              })
            )
          );
        });
    } else {
      this.set("categoryPermissionsHint", DEFAULT_HINT);
      this.set("autoJoinWarning", "");
    }
  }

  // intentionally not showing AJAX error for this, we will autogenerate
  // the slug server-side if they leave it blank
  _generateSlug(name) {
    ajax("/slugs/generate.json", { type: "GET", data: { name } }).then(
      (response) => {
        this.set("autoGeneratedSlug", response.slug);
      }
    );
  }

  _debouncedGenerateSlug(name) {
    cancel(this.generateSlugHandler);
    this._clearAutoGeneratedSlug();
    if (!name) {
      return;
    }
    this.generateSlugHandler = discourseDebounce(
      this,
      this._generateSlug,
      name,
      300
    );
  }

  _clearAutoGeneratedSlug() {
    this.set("autoGeneratedSlug", "");
  }

  @action
  onCategoryChange(categoryId) {
    let category = categoryId
      ? this.site.categories.findBy("id", categoryId)
      : null;
    this._updatePermissionsHint(category);

    const name = category?.name || "";
    this.setProperties({
      categoryId,
      category,
      name,
    });
    this._debouncedGenerateSlug(name);
  }

  @action
  onNameChange(name) {
    this._debouncedGenerateSlug(name);
  }

  @action
  create() {
    if (this.createDisabled) {
      return;
    }

    if (this.autoJoinUsers) {
      this.dialog.yesNoConfirm({
        message: this.autoJoinWarning,
        didConfirm: () => this._createChannel(),
      });
    } else {
      this._createChannel();
    }
  }
}
