# frozen_string_literal: true

module PageObjects
  module Pages
    class AdminFlags < PageObjects::Pages::Base
      def toggle(key)
        PageObjects::Components::DToggleSwitch.new(".#{key}").toggle
      end
    end
  end
end
