# frozen_string_literal: true

class Stat
  def initialize(
    name,
    show_in_ui: false,
    expose_via_api: false,
    expose_to_discourse_hub: false,
    &block
  )
    @name = name
    @show_in_ui = show_in_ui
    @expose_via_api = expose_via_api
    @expose_to_discourse_hub = expose_to_discourse_hub
    @block = block
  end

  attr_reader :name, :expose_via_api, :show_in_ui, :expose_to_discourse_hub

  def calculate
    @block.call.transform_keys { |key| build_key(key) }
  rescue StandardError => err
    Discourse.warn_exception(err, message: "Unexpected error when collecting #{@name} About stats.")
    {}
  end

  def self.all_stats
    calculate(_all_stats)
  end

  def self.api_stats
    calculate(_api_stats)
  end

  def self.discourse_hub_stats
    calculate(_discourse_hub_stats)
  end

  private

  def build_key(key)
    "#{@name}_#{key}".to_sym
  end

  def self._all_stats
    core_stats.concat(plugin_stats)
  end

  def self.calculate(stats)
    stats.map { |stat| stat.calculate }.reduce(Hash.new, :merge)
  end

  def self.core_stats
    result = [
      Stat.new("topics", show_in_ui: true, expose_via_api: true) { Statistics.topics },
      Stat.new("posts", show_in_ui: true, expose_via_api: true) { Statistics.posts },
      Stat.new("users", show_in_ui: true, expose_via_api: true) { Statistics.users },
      Stat.new("active_users", show_in_ui: true, expose_via_api: true) { Statistics.active_users },
      Stat.new("likes", show_in_ui: true, expose_via_api: true) { Statistics.likes },
    ]

    if SiteSetting.include_in_discourse_discover?
      result << Stat.new(
        "discourse_discover",
        show_in_ui: false,
        expose_via_api: false,
        expose_to_discourse_hub: true,
      ) { About.discourse_discover }
    end

    result
  end

  def self._api_stats
    _all_stats.select { |stat| stat.expose_via_api }
  end

  def self._discourse_hub_stats
    _all_stats.select { |stat| stat.expose_to_discourse_hub }
  end

  def self.plugin_stats
    DiscoursePluginRegistry.stats
  end

  private_class_method :_all_stats, :calculate, :core_stats, :_api_stats, :plugin_stats
end
