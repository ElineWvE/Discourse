# frozen_string_literal: true

require_relative "sidebar_edit_navigation_modal"

module PageObjects
  module Modals
    class SidebarEditTags < SidebarEditNavigationModal
      def has_tag_checkboxes?(tags)
        tag_checkboxes =
          all(".sidebar-tags-form .sidebar-tags-form__tag-label-name", count: tags.length)

        expect(tag_checkboxes.map(&:text)).to eq(tags.map(&:name))
      end

      def has_no_tag_checkboxes?
        has_no_css?(".sidebar-tags-form .sidebar-tags-form__tag") &&
          has_css?(
            ".sidebar-tags-form .sidebar-tags-form__no-tags",
            text: I18n.t("js.sidebar.tags_form_modal.no_tags"),
          )
      end

      def toggle_tag_checkbox(tag)
        find(
          ".sidebar-tags-form .sidebar-tags-form__tag[data-tag-name='#{tag.name}'] .sidebar-tags-form__input",
        ).click

        self
      end
    end
  end
end
