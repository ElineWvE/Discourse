# frozen_string_literal: true

module PageObjects
  module Components
    class SelectKit < PageObjects::Components::Base
      attr_reader :element

      def initialize(element)
        @element = element
      end

      def is_expanded?
        element.has_css?(".is-expanded")
      end

      def is_collapsed?
        element.has_css?(":not(.is-expanded)")
      end

      def has_selected_value?(value)
        element.find(".select-kit-header[data-value='#{value}']")
      end

      def has_selected_name?(name)
        element.find(".select-kit-header[data-name='#{name}']")
      end

      def has_selected_choice_name?(name)
        element.find(".selected-choice[data-name='#{name}']")
      end

      def has_option_name?(name)
        element.find(".select-kit-collection li[data-name='#{name}']")
      end

      def expand
        element.find(":not(.is-expanded) .select-kit-header").click
      end

      def collapse
        element.find(".is-expanded .select-kit-header").click
      end

      def select_row_by_value(value)
        expand
        element.find(".select-kit-row[data-value='#{value}']").click
      end

      def select_row_by_name(name)
        expand
        element.find(".select-kit-row[data-name='#{name}']").click
      end
    end
  end
end
