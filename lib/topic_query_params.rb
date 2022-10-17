# frozen_string_literal: true

module TopicQueryParams
  def build_topic_list_options
    options = {}
    params[:tags] = [params[:tag_id]] if params[:tag_id].present? && guardian.can_tag_pms?

    TopicQuery.public_valid_options.each do |key|
      if params.key?(key)
        val = options[key] = params[key]
        if !TopicQuery.validate?(key, val)
          raise Discourse::InvalidParameters.new key
        end
      end
    end

    # hacky columns get special handling
    options[:topic_ids] = param_to_integer_list(:topic_ids)
    options[:no_subcategories] = options[:no_subcategories] == 'true' if options[:no_subcategories].present?

    if hide_welcome_topic?
      if options[:except_topic_ids].nil?
        options[:except_topic_ids] = [SiteSetting.welcome_topic_id]
      else
        options[:except_topic_ids] << SiteSetting.welcome_topic_id
      end
    end

    options
  end

  private

  def hide_welcome_topic?
    return false if @guardian.is_admin?
    Site.welcome_topic_exists_and_is_not_edited?
  end
end
