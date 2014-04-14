# Handle sending a message to a user from the system.
require_dependency 'post_creator'
require_dependency 'topic_subtype'
require_dependency 'discourse'

class SystemMessage

  def self.create(recipient, type, params = {})
    self.new(recipient).create(type, params)
  end

  def initialize(recipient)
    @recipient = recipient
  end

  def create(type, params = {})
    params = defaults.merge(params)

    title = I18n.t("system_messages.#{type}.subject_template", params)
    raw = I18n.t("system_messages.#{type}.text_body_template", params)

    PostCreator.create(Discourse.site_contact_user,
                       title: title,
                       raw: raw,
                       archetype: Archetype.private_message,
                       target_usernames: @recipient.username,
                       subtype: TopicSubtype.system_message)
  end

  def defaults
    {
      site_name: SiteSetting.title,
      username: @recipient.username,
      user_preferences_url: "#{Discourse.base_url}/users/#{@recipient.username_lower}/preferences",
      new_user_tips: SiteContent.content_for(:usage_tips),
      site_password: "",
      base_url: Discourse.base_url,
      name: @recipient.name,
    }
  end

end
