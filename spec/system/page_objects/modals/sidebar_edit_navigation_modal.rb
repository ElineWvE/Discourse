# frozen_string_literal: true

module PageObjects
  module Modals
    class SidebarEditNavigationModal < PageObjects::Modals::Base
      def has_focus_on_filter_input?
        evaluate_script("document.activeElement").native ==
          find(".sidebar__edit-navigation-modal-form__filter-input-field").native
      end

      def filter(text)
        find(".sidebar__edit-navigation-modal-form__filter-input-field").fill_in(with: text)
        self
      end

      def click_reset_to_defaults_button
        click_button(I18n.t("js.sidebar.edit_navigation_modal_form.reset_to_defaults"))
        self
      end

      def has_no_reset_to_defaults_button?
        has_no_button?(I18n.t("js.sidebar.edit_navigation_modal_form.reset_to_defaults"))
      end

      def save
        find(".sidebar__edit-navigation-modal-form__save-button").click
        self
      end

      def deselect_all
        click_button(I18n.t("js.sidebar.edit_navigation_modal_form.deselect_button_text"))
        self
      end
    end
  end
end
