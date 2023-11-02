// DO NOT EDIT THIS FILE!!!
// Update it by running `rake javascript:update_constants`

export const ADMIN_NAV_MAP = [
  {
    name: "root",
    text: "Root",
    links: [
      { name: "admin-revamp", route: "admin-revamp", text: "Revamp" },
      { name: "admin", route: "admin", text: "Admin" },
    ],
  },
  {
    name: "plugins",
    text: "Plugins",
    links: [{ name: "admin_plugins", route: "adminPlugins", text: "Plugins" }],
  },
  {
    name: "site_settings",
    text: "Site Settings",
    links: [
      {
        name: "admin_site_settings",
        route: "adminSiteSettings",
        text: "Site Settings",
      },
    ],
  },
  {
    name: "reports",
    text: "Reports",
    links: [{ name: "admin_reports", route: "adminReports", text: "Reports" }],
  },
  {
    name: "users",
    text: "Users",
    links: [
      { name: "admin_users_list", route: "adminUsersList", text: "List" },
      { name: "admin_users", route: "adminUsers", text: "Users" },
    ],
  },
  {
    name: "email",
    text: "Email",
    links: [
      { name: "admin_email_sent", route: "adminEmail.sent", text: "Sent" },
      {
        name: "admin_email_skipped",
        route: "adminEmail.skipped",
        text: "Skipped",
      },
      {
        name: "admin_email_bounced",
        route: "adminEmail.bounced",
        text: "Bounced",
      },
      {
        name: "admin_email_received",
        route: "adminEmail.received",
        text: "Received",
      },
      {
        name: "admin_email_rejected",
        route: "adminEmail.rejected",
        text: "Rejected",
      },
      {
        name: "admin_email_preview-digest",
        route: "adminEmail.previewDigest",
        text: "Preview Digest",
      },
      {
        name: "admin_email_advanced-test",
        route: "adminEmail.advancedTest",
        text: "Advanced Test",
      },
      { name: "admin_email", route: "adminEmail", text: "Email" },
    ],
  },
  {
    name: "logs",
    text: "Logs",
    links: [
      {
        name: "admin_logs_staff_action_logs",
        route: "adminLogs.staffActionLogs",
        text: "Staff Action Logs",
      },
      {
        name: "admin_logs_screened_emails",
        route: "adminLogs.screenedEmails",
        text: "Screened Emails",
      },
      {
        name: "admin_logs_screened_ip_addresses",
        route: "adminLogs.screenedIpAddresses",
        text: "Screened Ip Addresses",
      },
      {
        name: "admin_logs_screened_urls",
        route: "adminLogs.screenedUrls",
        text: "Screened Urls",
      },
      {
        name: "admin_logs_search_logs",
        route: "adminSearchLogs",
        text: "Search Logs",
      },
      {
        name: "admin_logs_search_logs_term",
        route: "adminSearchLogs.term",
        text: "Search Term",
      },
      { name: "admin_logs", route: "adminLogs", text: "Logs" },
    ],
  },
  {
    name: "customize",
    text: "Customize",
    links: [
      { name: "admin_customize", route: "adminCustomize", text: "Customize" },
      {
        name: "admin_customize_themes",
        route: "adminCustomizeThemes",
        text: "Themes",
      },
      {
        name: "admin_customize_colors",
        route: "adminCustomize.colors",
        text: "Colors",
      },
      {
        name: "admin_customize_permalinks",
        route: "adminPermalinks",
        text: "Permalinks",
      },
      {
        name: "admin_customize_embedding",
        route: "adminEmbedding",
        text: "Embedding",
      },
      {
        name: "admin_customize_user_fields",
        route: "adminUserFields",
        text: "User Fields",
      },
      { name: "admin_customize_emojis", route: "adminEmojis", text: "Emojis" },
      {
        name: "admin_customize_form-templates",
        route: "adminCustomizeFormTemplates",
        text: "Form Templates",
      },
      {
        name: "admin_customize_form-templates_new",
        route: "adminCustomizeFormTemplates.new",
        text: "Form Templates New",
      },
      {
        name: "admin_customize_site_texts",
        route: "adminSiteText",
        text: "Site Texts",
      },
      {
        name: "admin_customize_email_templates",
        route: "adminCustomizeEmailTemplates",
        text: "Email Templates",
      },
      {
        name: "admin_customize_robots",
        route: "adminCustomizeRobotsTxt",
        text: "Robots",
      },
      {
        name: "admin_customize_email_style",
        route: "adminCustomizeEmailStyle",
        text: "Email Style",
      },
      {
        name: "admin_customize_watched_words",
        route: "adminWatchedWords",
        text: "Watched Words",
      },
    ],
  },
  {
    name: "dashboard",
    text: "Dashboard",
    links: [
      {
        name: "admin_dashboard_moderation",
        route: "admin.dashboardModeration",
        text: "Moderation",
      },
      {
        name: "admin_dashboard_security",
        route: "admin.dashboardSecurity",
        text: "Security",
      },
      {
        name: "admin_dashboard_reports",
        route: "admin.dashboardReports",
        text: "Reports",
      },
    ],
  },
  {
    name: "api",
    text: "Api",
    links: [
      { name: "admin_api_keys", route: "adminApiKeys", text: "Keys" },
      {
        name: "admin_api_web_hooks",
        route: "adminWebHooks",
        text: "Web Hooks",
      },
      { name: "admin_api", route: "adminApi", text: "Api" },
    ],
  },
  {
    name: "backups",
    text: "Backups",
    links: [
      { name: "admin_backups_logs", route: "admin.backups.logs", text: "Logs" },
      { name: "admin_backups", route: "admin.backups", text: "Backups" },
    ],
  },
  {
    name: "badges",
    text: "Badges",
    links: [{ name: "admin_badges", route: "adminBadges", text: "Badges" }],
  },
];
