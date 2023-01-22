# frozen_string_literal: true

class DropFlairUrlFromGroups < ActiveRecord::Migration[7.0]
  DROPPED_COLUMNS ||= { groups: %i[flair_url] }

  def up
    DROPPED_COLUMNS.each { |table, columns| Migration::ColumnDropper.execute_drop(table, columns) }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
