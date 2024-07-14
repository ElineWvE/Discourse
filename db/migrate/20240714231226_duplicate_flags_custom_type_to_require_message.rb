# frozen_string_literal: true

class DuplicateFlagsCustomTypeToRequireMessage < ActiveRecord::Migration[7.1]
  def up
    add_column :flags, :require_message, :boolean, default: false, null: false

    Migration::ColumnDropper.mark_readonly("flags", "custom_type")

    DB.exec <<~SQL
      UPDATE flags
      SET require_message = custom_type
    SQL
  end

  def down
    remove_column :flags, :require_message
  end
end
