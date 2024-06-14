# frozen_string_literal: true

class UpdateSiteSetting
  include Service::Base

  policy :current_user_is_admin

  step :convert_name_to_sym

  policy :setting_is_visible
  policy :setting_is_configurable

  step :cleanup_value
  step :save

  private

  def convert_name_to_sym(setting_name:)
    context.setting_name = setting_name.to_sym
  end

  def current_user_is_admin(current_user:)
    current_user.admin?
  end

  def setting_is_visible(setting_name:)
    context.allow_changing_hidden || !SiteSetting.hidden_settings.include?(setting_name)
  end

  def setting_is_configurable(setting_name:)
    return true if !SiteSetting.plugins[setting_name]

    Discourse.plugins_by_name[SiteSetting.plugins[setting_name]].configurable?
  end

  def cleanup_value(setting_name:, new_value:)
    new_value = new_value.strip if new_value.is_a?(String)

    case SiteSetting.type_supervisor.get_type(setting_name)
    when :integer
      new_value = new_value.tr("^-0-9", "").to_i if new_value.is_a?(String)
    when :file_size_restriction
      new_value = new_value.tr("^0-9", "").to_i if new_value.is_a?(String)
    when :uploaded_image_list
      new_value = new_value.blank? ? "" : Upload.get_from_urls(new_value.split("|")).to_a
    when :upload
      new_value = Upload.get_from_url(new_value) || ""
    end
    context.new_value = new_value
  end

  def save(setting_name:, new_value:, current_user:)
    SiteSetting.set_and_log(setting_name, new_value, current_user)
  end
end
