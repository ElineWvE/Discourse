# frozen_string_literal: true

class PostActionType < ActiveRecord::Base
  POST_ACTION_TYPE_ALL_FLAGS_KEY = "post_action_type_all_flags"
  POST_ACTION_TYPE_PUBLIC_TYPE_IDS_KEY = "post_action_public_type_ids"
<<<<<<< HEAD
  LIKE_POST_ACTION_ID = 2

  after_save { expire_cache if !skip_expire_cache_callback }
  after_destroy { expire_cache if !skip_expire_cache_callback }

  attr_accessor :skip_expire_cache_callback
=======

  after_save :expire_cache
  after_destroy :expire_cache
>>>>>>> 8f6a543278 (DEV: Use redis for flag cache)

  include AnonCacheInvalidator

  def expire_cache
    ApplicationSerializer.expire_cache_fragment!(/\Apost_action_types_/)
    ApplicationSerializer.expire_cache_fragment!(/\Apost_action_flag_types_/)
  end

  class << self
    attr_reader :flag_settings

    def initialize_flag_settings
      @flag_settings = FlagSettings.new
    end

    def replace_flag_settings(settings)
      Discourse.deprecate("Flags should not be replaced. Insert custom flags as database records.")
      @flag_settings = settings || FlagSettings.new
    end

    def types
      if overridden_by_plugin_or_skipped_db?
        return Enum.new(like: 2).merge!(flag_settings.flag_types)
      end
      Enum.new(like: 2).merge(flag_types)
    end

    def expire_cache
      Discourse.redis.keys("post_action_types_*").each { |key| Discourse.redis.del(key) }
      Discourse.redis.keys("post_action_flag_types_*").each { |key| Discourse.redis.del(key) }
      Discourse.redis.del(POST_ACTION_TYPE_ALL_FLAGS_KEY)
      Discourse.redis.del(POST_ACTION_TYPE_PUBLIC_TYPE_IDS_KEY)
    end

    def reload_types
      @flag_settings = FlagSettings.new
      ReviewableScore.reload_types
      PostActionType.new.expire_cache
      PostActionType.expire_cache
    end

    def overridden_by_plugin_or_skipped_db?
      flag_settings.flag_types.present? || GlobalSetting.skip_db?
    end

    def all_flags
      cached_all_flags = Discourse.redis.get(POST_ACTION_TYPE_ALL_FLAGS_KEY)
      return JSON.parse(cached_all_flags).map { |flag| Flag.new(flag) } if cached_all_flags

      begin
        flags = Flag.unscoped.order(:position).all
        Discourse.redis.set(
          POST_ACTION_TYPE_ALL_FLAGS_KEY,
          flags.as_json(
            only: %i[
              id
              name
              name_key
              description
              notify_type
              auto_action_type
              require_message
              applies_to
              position
              enabled
              score_type
            ],
          ).to_json,
        )
        flags
      end
    end

    def auto_action_flag_types
      return flag_settings.auto_action_types if overridden_by_plugin_or_skipped_db?
      flag_enum(all_flags.select(&:auto_action_type))
    end

    def public_types
      types.except(*flag_types.keys << :notify_user)
    end

    def public_type_ids
      cached_public_type_ids = Discourse.redis.get(POST_ACTION_TYPE_PUBLIC_TYPE_ID_KEY)
      return JSON.parse(cached_public_type_ids) if cached_public_type_ids

      begin
        public_type_id_values = public_types.values
        Discourse.redis.set(POST_ACTION_TYPE_PUBLIC_TYPE_ID_KEY, public_type_id_values.to_json)
        public_type_id_values
      end
    end

    def flag_types_without_additional_message
      return flag_settings.without_additional_message_types if overridden_by_plugin_or_skipped_db?
      flag_enum(all_flags.reject(&:require_message))
    end

    def flag_types
      return flag_settings.flag_types if overridden_by_plugin_or_skipped_db?

      # Once replace_flag API is fully deprecated, then we can drop respond_to. It is needed right now for migration to be evaluated.
      # TODO (krisk)
      flag_enum(all_flags.reject { |flag| flag.respond_to?(:score_type) && flag.score_type })
    end

    def score_types
      return flag_settings.flag_types if overridden_by_plugin_or_skipped_db?

      # Once replace_flag API is fully deprecated, then we can drop respond_to. It is needed right now for migration to be evaluated.
      # TODO (krisk)
      flag_enum(all_flags.filter { |flag| flag.respond_to?(:score_type) && flag.score_type })
    end

    # flags resulting in mod notifications
    def notify_flag_type_ids
      notify_flag_types.values
    end

    def notify_flag_types
      return flag_settings.notify_types if overridden_by_plugin_or_skipped_db?
      flag_enum(all_flags.select(&:notify_type))
    end

    def topic_flag_types
      if overridden_by_plugin_or_skipped_db?
        flag_settings.topic_flag_types
      else
        flag_enum(all_flags.select { |flag| flag.applies_to?("Topic") })
      end
    end

    def disabled_flag_types
      flag_enum(all_flags.reject(&:enabled))
    end

    def enabled_flag_types
      flag_enum(all_flags.filter(&:enabled))
    end

    def additional_message_types
      return flag_settings.additional_message_types if overridden_by_plugin_or_skipped_db?
      flag_enum(all_flags.select(&:require_message))
    end

    def names
      all_flags.map { |f| [f.id, f.name] }.to_h
    end

    def descriptions
      all_flags.map { |f| [f.id, f.description] }.to_h
    end

    def applies_to
      all_flags.map { |f| [f.id, f.applies_to] }.to_h
    end

    def is_flag?(sym)
      flag_types.valid?(sym)
    end

    private

    def flag_enum(scope)
      Enum.new(scope.map { |flag| [flag.name_key.to_sym, flag.id] }.to_h)
    end
  end

  initialize_flag_settings
end

# == Schema Information
#
# Table name: post_action_types
#
#  name_key            :string(50)       not null
#  is_flag             :boolean          default(FALSE), not null
#  icon                :string(20)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  id                  :integer          not null, primary key
#  position            :integer          default(0), not null
#  score_bonus         :float            default(0.0), not null
#  reviewable_priority :integer          default(0), not null
#
