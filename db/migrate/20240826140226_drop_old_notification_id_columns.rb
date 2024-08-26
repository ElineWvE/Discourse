# frozen_string_literal: true

class DropOldNotificationIdColumns < ActiveRecord::Migration[7.1]
  def up
    Migration::SafeMigrate.disable!

    if column_exists?(:notifications, :old_id)
      Migration::ColumnDropper.drop_readonly(:notifications, :old_id)
      remove_column :notifications, :old_id
    end

    if column_exists?(:shelved_notifications, :old_notification_id)
      Migration::ColumnDropper.drop_readonly(:shelved_notifications, :old_notification_id)
      remove_column :shelved_notifications, :old_notification_id
    end

    if column_exists?(:user_badges, :old_notification_id)
      Migration::ColumnDropper.drop_readonly(:user_badges, :old_notification_id)
      remove_column :user_badges, :old_notification_id
    end
  ensure
    Migration::SafeMigrate.enable!
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
