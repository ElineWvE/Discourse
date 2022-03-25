# frozen_string_literal: true

class CreateTagGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :tag_groups do |t|
      t.string :name,       null: false
      t.integer :tag_count, null: false, default: 0
      t.timestamps null: false
    end

    create_table :tag_group_memberships do |t|
      t.integer :tag_id, null: false
      t.integer :tag_group_id, null: false
      t.timestamps null: false
    end

    add_index :tag_group_memberships, [:tag_group_id, :tag_id], unique: true
  end
end
