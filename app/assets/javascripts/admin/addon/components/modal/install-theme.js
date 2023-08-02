import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action, set } from "@ember/object";
import { match } from "@ember/object/computed";
import { COMPONENTS, THEMES } from "admin/models/theme";
import { POPULAR_THEMES } from "discourse-common/lib/popular-themes";
import { ajax } from "discourse/lib/ajax";
import I18n from "I18n";

const MIN_NAME_LENGTH = 4;

export default class InstallTheme extends Component {
  @tracked selection = this.args.model.selection || "popular";
  @tracked uploadUrl = this.args.model.uploadUrl;
  @tracked uploadName = this.args.model.uploadName;
  @tracked advancedVisible = false;
  @tracked loading = false;
  @tracked localFile;
  @tracked publicKey;
  @tracked branch;
  @tracked duplicateRemoteThemeWarning;
  @tracked flash;
  @tracked themeCannotBeInstalled;

  recordType = "theme";
  importUrl = "/admin/themes/import";
  keyGenUrl = "/admin/themes/generate_key_pair";

  @match("uploadUrl", /^ssh:\/\/.+@.+$|.+@.+:.+$/) checkPrivate;

  get submitLabel() {
    if (this.themeCannotBeInstalled) {
      return "admin.customize.theme.create_placeholder";
    }

    return `admin.customize.theme.${
      this.selection === "create" ? "create" : "install"
    }`;
  }

  get component() {
    this.args.model.selectedType === COMPONENTS;
  }

  get local() {
    return this.selection === "local";
  }

  get remote() {
    return this.selection === "remote";
  }

  get create() {
    return this.selection === "create";
  }

  get directRepoInstall() {
    return this.selection === "directRepoInstall";
  }

  get popular() {
    return this.selection === "popular";
  }

  get nameTooShort() {
    return !this.name || this.name.length < MIN_NAME_LENGTH;
  }

  get installDisabled() {
    return (
      this.loading ||
      (this.remote && !this.uploadUrl) ||
      (this.local && !this.localFile) ||
      (this.create && this.nameTooShort)
    );
  }

  get placeholder() {
    if (this.component) {
      return I18n.t("admin.customize.theme.component_name");
    } else {
      return I18n.t("admin.customize.theme.theme_name");
    }
  }

  get themes() {
    return POPULAR_THEMES.map((t) => {
      if (
        this.args.model.installedThemes.some((theme) =>
          this.themeHasSameUrl(theme, t.value)
        )
      ) {
        set(t, "installed", true);
      }
      return t;
    });
  }

  themeHasSameUrl(theme, url) {
    const themeUrl = theme.remote_theme && theme.remote_theme.remote_url;
    return (
      themeUrl &&
      url &&
      url.replace(/\.git$/, "") === themeUrl.replace(/\.git$/, "")
    );
  }

  @action
  privateWasChecked() {
    const checked = this.checkPrivate;
    if (checked && !this._keyLoading && !this.publicKey) {
      this._keyLoading = true;
      ajax(this.keyGenUrl, { type: "POST" })
        .then((pair) => {
          this.publicKey = pair.public_key;
        })
        .catch(popupAjaxError)
        .finally(() => {
          this._keyLoading = false;
        });
    }
  }

  @action
  toggleAdvanced() {
    this.advancedVisible = !this.advancedVisible;
  }

  // willDestroy() {
  //   this.duplicateRemoteThemeWarning = null;
  //   this.localFile = null;
  //   this.uploadUrl = null;
  //   this.publicKey = null;
  //   this.branch = null;
  //   this.selection = "popular";

  //   this.themesController.repoName = null;
  //   this.themesController.repoUrl = null;
  // }

  @action
  uploadLocaleFile() {
    this.localFile = document.getElementById("file-input").files[0];
  }

  @action
  installThemeFromList(url) {
    this.uploadUrl = url;
    this.installTheme();
  }

  @action
  async installTheme() {
    if (this.create) {
      this.loading = true;
      const theme = this.store.createRecord(this.recordType);
      try {
        await theme.save({ name: this.name, component: this.component });
        this.args.model.addTheme(theme);
        this.args.closeModal();
      } catch (e) {
        this.flash = e.jqXHR.responseJSON.errors[0];
      } finally {
        this.loading = false;
      }
      return;
    }

    let options = {
      type: "POST",
    };

    if (this.local) {
      options.processData = false;
      options.contentType = false;
      options.data = new FormData();
      options.data.append("theme", this.localFile);
    }

    if (this.remote || this.popular || this.directRepoInstall) {
      const duplicate = this.args.model.content.find((theme) =>
        this.themeHasSameUrl(theme, this.uploadUrl)
      );
      if (duplicate && !this.duplicateRemoteThemeWarning) {
        const warning = I18n.t("admin.customize.theme.duplicate_remote_theme", {
          name: duplicate.name,
        });
        this.duplicateRemoteThemeWarning = warning;
        return;
      }
      options.data = {
        remote: this.uploadUrl,
        branch: this.branch,
        public_key: this.publicKey,
      };
    }

    // User knows that theme cannot be installed, but they want to continue
    // to force install it.
    if (this.themeCannotBeInstalled) {
      options.data["force"] = true;
    }
    if (this.model.user_id) {
      // Used by theme-creator
      options.data["user_id"] = this.model.user_id;
    }
    this.loading = true;

    try {
      const result = await ajax(this.importUrl, options);
      const theme = this.store.createRecord(this.recordType, result.theme);
      this.args.model.addTheme(theme);
      this.args.closeModal();
      this.publicKey = null;
    } catch (e) {
      if (!this.publicKey || this.themeCannotBeInstalled) {
        // look into this
        this.flash = e.jqXHR.responseJSON.errors[0];
      }
      this.themeCannotBeInstalled = I18n.t(
        "admin.customize.theme.force_install"
      );
    } finally {
      this.loading = false;
    }
  }
}
