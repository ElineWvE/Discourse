import Component from "@glimmer/component";
import { service } from "@ember/service";
import { eq, not, or } from "truth-helpers";
import DAG from "discourse/lib/dag";
import getURL from "discourse-common/lib/get-url";
import Dropdown from "./dropdown";
import UserDropdown from "./user-dropdown";

let headerIcons;
resetHeaderIcons();

function resetHeaderIcons() {
  headerIcons = new DAG({ defaultPosition: { before: "search" } });
  headerIcons.add("search");
  headerIcons.add("hamburger", undefined, { after: "search" });
  headerIcons.add("user-menu", undefined, { after: "hamburger" });
}

export function headerIconsDAG() {
  return headerIcons;
}

export function clearExtraHeaderIcons() {
  resetHeaderIcons();
}

export default class Icons extends Component {
  @service site;
  @service currentUser;
  @service siteSettings;
  @service header;
  @service search;

  get showHamburger() {
    // NOTE: In this scenario, we are forcing the sidebar on admin users,
    // so we need to still show the hamburger menu to be able to
    // access the legacy hamburger forum menu.
    if (
      this.currentUser?.use_admin_sidebar &&
      this.args.sidebarEnabled &&
      this.siteSettings.navigation_menu === "header dropdown"
    ) {
      return true;
    }

    return !this.args.sidebarEnabled || this.site.mobileView;
  }

  <template>
    <ul class="icons d-header-icons">
      {{#each (headerIcons.resolve) as |entry|}}
        {{#if (eq entry.key "search")}}
          <Dropdown
            @title="search.title"
            @icon="search"
            @iconId={{@searchButtonId}}
            @onClick={{@toggleSearchMenu}}
            @active={{this.search.visible}}
            @href={{getURL "/search"}}
            @className="search-dropdown"
            @targetSelector=".search-menu-panel"
          />
        {{else if (eq entry.key "hamburger")}}
          {{#if this.showHamburger}}
            <Dropdown
              @title="hamburger_menu"
              @icon="bars"
              @iconId="toggle-hamburger-menu"
              @active={{this.header.hamburgerVisible}}
              @onClick={{@toggleHamburger}}
              @className="hamburger-dropdown"
            />
          {{/if}}
        {{else if (eq entry.key "user-menu")}}
          {{#if this.currentUser}}
            <UserDropdown
              @active={{this.header.userVisible}}
              @toggleUserMenu={{@toggleUserMenu}}
            />
          {{/if}}
        {{else if entry.value}}
          <entry.value />
        {{/if}}
      {{/each}}
    </ul>
  </template>
}
