import getURL from "discourse-common/lib/get-url";

export const ADMIN_NAV_MAP = [
  {
    name: "account",
    label: "admin.account.title",
    links: [
      {
        name: "admin_backups",
        route: "admin.backups",
        label: "admin.account.sidebar_link.backups",
        icon: "archive",
      },
      {
        name: "admin_whats_new",
        route: "admin.whatsNew",
        label: "admin.account.sidebar_link.whats_new.title",
        icon: "gift",
        keywords: "admin.account.sidebar_link.whats_new.keywords",
        moderator: true,
      },
    ],
  },
  {
    name: "reports",
    label: "admin.reports.sidebar_title",
    links: [
      {
        name: "admin_all_reports",
        route: "adminReports.index",
        label: "admin.reports.sidebar_link.all",
        icon: "chart-bar",
        moderator: true,
      },
    ],
  },
  {
    name: "community",
    label: "admin.community.title",
    links: [
      {
        name: "admin_about_your_site",
        route: "adminSiteSettingsCategory",
        routeModels: ["required"],
        query: { filter: "" },
        label: "admin.community.sidebar_link.about_your_site",
        icon: "cog",
      },
      {
        name: "admin_badges",
        route: "adminBadges",
        label: "admin.community.sidebar_link.badges",
        icon: "certificate",
      },
      {
        name: "admin_login_and_authentication",
        route: "adminSiteSettingsCategory",
        routeModels: ["login"],
        query: { filter: "" },
        label: "admin.community.sidebar_link.login_and_authentication",
        icon: "unlock",
      },
      {
        name: "admin_notifications",
        route: "adminSiteSettingsCategory",
        routeModels: ["all_results"],
        query: { filter: "notifications" },
        label: "admin.community.sidebar_link.notifications",
        icon: "bell",
      },
      {
        name: "admin_permalinks",
        route: "adminPermalinks",
        label: "admin.community.sidebar_link.permalinks",
        icon: "link",
      },
      {
        name: "admin_trust_levels",
        route: "adminSiteSettingsCategory",
        routeModels: ["trust"],
        query: { filter: "" },
        label: "admin.community.sidebar_link.trust_levels",
        icon: "user-shield",
      },
      {
        name: "admin_user_fields",
        route: "adminUserFields",
        label: "admin.community.sidebar_link.user_fields",
        icon: "user-edit",
      },
      {
        name: "admin_watched_words",
        route: "adminWatchedWords",
        label: "admin.community.sidebar_link.watched_words",
        icon: "eye",
        moderator: true,
      },
      {
        name: "admin_legal",
        route: "adminSiteSettingsCategory",
        routeModels: ["legal"],
        query: { filter: "" },
        label: "admin.community.sidebar_link.legal",
        icon: "gavel",
      },
    ],
  },
  {
    name: "appearance",
    label: "admin.appearance.title",
    links: [
      {
        name: "admin_font_style",
        route: "adminSiteSettingsCategory",
        routeModels: ["all_results"],
        query: { filter: "font" },
        label: "admin.appearance.sidebar_link.font_style",
        icon: "italic",
      },
      {
        name: "admin_site_logo",
        route: "adminSiteSettingsCategory",
        routeModels: ["branding"],
        query: { filter: "" },
        label: "admin.appearance.sidebar_link.site_logo",
        icon: "fab-discourse",
      },
      {
        name: "admin_color_schemes",
        route: "adminCustomize.colors",
        label: "admin.appearance.sidebar_link.color_schemes",
        icon: "palette",
      },
      {
        name: "admin_emoji",
        route: "adminEmojis",
        label: "admin.appearance.sidebar_link.emoji",
        icon: "discourse-emojis",
      },
      {
        name: "admin_navigation",
        route: "adminSiteSettingsCategory",
        routeModels: ["all_results"],
        query: { filter: "navigation" },
        label: "admin.appearance.sidebar_link.navigation",
        icon: "project-diagram",
      },
      {
        name: "admin_themes",
        route: "adminCustomizeThemes",
        routeModels: ["themes"],
        model: "themes",
        label: "admin.appearance.sidebar_link.themes",
        icon: "paint-brush",
      },
      {
        name: "admin_components",
        route: "adminCustomizeThemes",
        routeModels: ["components"],
        label: "admin.appearance.sidebar_link.components.title",
        icon: "puzzle-piece",
        keywords: "admin.appearance.sidebar_link.components.keywords",
      },
      {
        name: "admin_customize_site_texts",
        route: "adminSiteText",
        label: "admin.appearance.sidebar_link.site_texts",
        icon: "language",
      },
    ],
  },
  {
    name: "email_settings",
    label: "admin.email_settings.title",
    links: [
      {
        name: "admin_appearance",
        route: "adminCustomizeEmailStyle",
        label: "admin.email_settings.sidebar_link.appearance",
        icon: "envelope",
      },
      {
        name: "admin_preview_summary",
        route: "adminEmail.previewDigest",
        label: "admin.email_settings.sidebar_link.preview_summary",
        icon: "notification.private_message",
      },
      {
        name: "admin_server_setup",
        route: "adminEmail.index",
        label: "admin.email_settings.sidebar_link.server_setup",
        icon: "cog",
      },
    ],
  },
  {
    name: "email_logs",
    label: "admin.email_logs.title",
    links: [
      {
        name: "admin_email_sent",
        route: "adminEmail.sent",
        label: "admin.email_logs.sidebar_link.sent",
        icon: "arrow-right",
      },
      {
        name: "admin_email_skipped",
        route: "adminEmail.skipped",
        label: "admin.email_logs.sidebar_link.skipped",
        icon: "angle-double-right",
      },
      {
        name: "admin_email_bounced",
        route: "adminEmail.bounced",
        label: "admin.email_logs.sidebar_link.bounced",
        icon: "times",
      },
      {
        name: "admin_email_received",
        route: "adminEmail.received",
        label: "admin.email_logs.sidebar_link.received",
        icon: "inbox",
      },
      {
        name: "admin_email_rejected",
        route: "adminEmail.rejected",
        label: "admin.email_logs.sidebar_link.rejected",
        icon: "ban",
      },
    ],
  },
  {
    name: "security",
    label: "admin.security.title",
    links: [
      {
        name: "admin_logs_error_logs",
        href: getURL("/logs"),
        label: "admin.security.sidebar_link.error_logs",
        icon: "external-link-alt",
      },
      {
        name: "admin_logs_screened_emails",
        route: "adminLogs.screenedEmails",
        label: "admin.security.sidebar_link.screened_emails",
        icon: "envelope",
        moderator: true,
      },
      {
        name: "admin_logs_screened_ip_addresses",
        route: "adminLogs.screenedIpAddresses",
        label: "admin.security.sidebar_link.screened_ips",
        icon: "globe",
        moderator: true,
      },
      {
        name: "admin_logs_screened_urls",
        route: "adminLogs.screenedUrls",
        label: "admin.security.sidebar_link.screened_urls",
        icon: "globe",
        moderator: true,
      },
      {
        name: "admin_logs_search_logs",
        route: "adminSearchLogs",
        label: "admin.security.sidebar_link.search_logs",
        icon: "search",
        moderator: true,
      },
      {
        name: "admin_security",
        route: "adminSiteSettingsCategory",
        routeModels: ["security"],
        query: { filter: "" },
        label: "admin.security.sidebar_link.security",
        icon: "lock",
      },
      {
        name: "admin_spam",
        route: "adminSiteSettingsCategory",
        routeModels: ["spam"],
        query: { filter: "" },
        label: "admin.security.sidebar_link.spam",
        icon: "robot",
      },
      {
        name: "admin_logs_staff_action_logs",
        route: "adminLogs.staffActionLogs",
        label: "admin.security.sidebar_link.staff_action_logs",
        icon: "user-shield",
        moderator: true,
      },
    ],
  },
  {
    name: "plugins",
    label: "admin.plugins.title",
    links: [
      {
        name: "admin_installed_plugins",
        route: "adminPlugins.index",
        label: "admin.plugins.sidebar_link.installed",
        icon: "puzzle-piece",
      },
    ],
  },
  {
    name: "advanced",
    label: "admin.advanced.title",
    links: [
      {
        name: "admin_api_keys",
        route: "adminApiKeys",
        icon: "key",
        label: "admin.advanced.sidebar_link.api_keys",
      },
      {
        name: "admin_developer",
        route: "adminSiteSettingsCategory",
        routeModels: ["developer"],
        query: { filter: "" },
        label: "admin.advanced.sidebar_link.developer",
        icon: "keyboard",
      },
      {
        name: "admin_embedding",
        route: "adminEmbedding",
        label: "admin.advanced.sidebar_link.embedding",
        icon: "code",
      },
      {
        name: "admin_rate_limits",
        route: "adminSiteSettingsCategory",
        routeModels: ["rate_limits"],
        query: { filter: "" },
        label: "admin.advanced.sidebar_link.rate_limits",
        icon: "rocket",
      },
      {
        name: "admin_user_api",
        route: "adminSiteSettingsCategory",
        routeModels: ["user_api"],
        query: { filter: "" },
        label: "admin.advanced.sidebar_link.user_api",
        icon: "random",
      },
      {
        name: "admin_api_web_hooks",
        route: "adminWebHooks",
        label: "admin.advanced.sidebar_link.web_hooks",
        icon: "globe",
      },
      {
        name: "admin_onebox",
        route: "adminSiteSettingsCategory",
        routeModels: ["onebox"],
        query: { filter: "" },
        label: "admin.advanced.sidebar_link.onebox",
        icon: "far-square",
      },
      {
        name: "admin_files",
        route: "adminSiteSettingsCategory",
        routeModels: ["files"],
        query: { filter: "" },
        label: "admin.advanced.sidebar_link.files",
        icon: "file",
      },
      {
        name: "admin_other_options",
        route: "adminSiteSettingsCategory",
        routeModels: ["uncategorized"],
        query: { filter: "" },
        label: "admin.advanced.sidebar_link.other_options",
        icon: "discourse-other-tab",
      },
      {
        name: "admin_search",
        route: "adminSiteSettingsCategory",
        routeModels: ["search"],
        query: { filter: "" },
        label: "admin.advanced.sidebar_link.search",
        icon: "search",
      },
      {
        name: "admin_experimental",
        route: "adminSiteSettingsCategory",
        routeModels: ["all_results"],
        query: { filter: "experimental" },
        label: "admin.advanced.sidebar_link.experimental",
        icon: "discourse-sparkles",
      },
    ],
  },
];
