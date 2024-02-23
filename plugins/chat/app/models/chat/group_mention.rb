# frozen_string_literal: true

module Chat
  class GroupMention < Mention
    belongs_to :group, foreign_key: :target_id

    def identifier
      group.name
    end

    def is_group_mention
      true
    end

    def is_mass_mention?
      false
    end

    def reached_users
      group.users.map { |user| user }
    end
  end
end
