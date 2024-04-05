# frozen_string_literal: true

module DiscourseAutomation
  class Triggerable
    attr_reader :fields, :name, :not_found, :settings, :automation

    MANUAL_TRIGGER_KEY = :manual_trigger

    def initialize(name, automation = nil)
      @name = name
      @placeholders = []
      @fields = []
      @settings = { MANUAL_TRIGGER_KEY => false }
      @on_update_block = proc {}
      @on_call_block = proc {}
      @not_found = false
      @validations = []
      @automation = automation

      eval! if @name
    end

    def id
      "trigger"
    end

    def scriptable?
      false
    end

    def triggerable?
      true
    end

    def validate(&block)
      @validations << block
    end

    def valid?(automation)
      @validations.each { |block| automation.instance_exec(&block) }

      automation.errors.blank?
    end

    def placeholders
      @placeholders.uniq.compact.map(&:to_sym)
    end

    def placeholder(*args)
      if args.present?
        @placeholders << args[0]
      elsif block_given?
        @placeholders =
          @placeholders.concat(Array(yield(@automation.serialized_fields, @automation)))
      end
    end

    def field(name, component:, **options)
      @fields << {
        name: name,
        component: component,
        extra: {
        },
        accepts_placeholders: false,
        accepted_contexts: [],
        required: false,
      }.merge(options || {})
    end

    def setting(key, value)
      @settings[key] = value
    end

    def enable_manual_trigger
      setting(MANUAL_TRIGGER_KEY, true)
    end

    def components
      fields.map { |f| f[:component] }.uniq
    end

    def eval!
      begin
        public_send("__triggerable_#{name.underscore}")
      rescue NoMethodError
        @not_found = true
      end

      self
    end

    def on_call(&block)
      if block_given?
        @on_call_block = block
      else
        @on_call_block
      end
    end

    def on_update(&block)
      if block_given?
        @on_update_block = block
      else
        @on_update_block
      end
    end

    def self.add(identifier, &block)
      @all_triggers = nil
      define_method("__triggerable_#{identifier}", block || proc {})
    end

    def self.all
      @all_triggers ||=
        DiscourseAutomation::Triggerable.instance_methods(false).grep(/^__triggerable_/)
    end
  end
end
