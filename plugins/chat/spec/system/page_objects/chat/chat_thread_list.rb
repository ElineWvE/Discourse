# frozen_string_literal: true

module PageObjects
  module Pages
    class ChatThreadList < PageObjects::Pages::Base
      def item_by_id(id)
        find(item_by_id_selector(id))
      end

      def avatar_selector(user)
        ".chat-thread-list-item__om-user-avatar .chat-user-avatar .chat-user-avatar-container[data-user-card=\"#{user.username}\"] img"
      end

      def has_no_unread_item?(id)
        has_no_css?(item_by_id_selector(id) + ".-is-unread")
      end

      def has_unread_item?(id, count: nil)
        if count.nil?
          has_css?(item_by_id_selector(id) + ".-is-unread")
        else
          has_css?(
            item_by_id_selector(id) + ".-is-unread .chat-thread-list-item-unread-indicator__number",
            text: count.to_s,
          )
        end
      end

      def item_by_id_selector(id)
        ".chat-thread-list__items .chat-thread-list-item[data-thread-id=\"#{id}\"]"
      end
    end
  end
end
