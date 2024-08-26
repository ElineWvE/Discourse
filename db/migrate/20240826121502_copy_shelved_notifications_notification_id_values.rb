# frozen_string_literal: true

class CopyShelvedNotificationsNotificationIdValues < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    # Short-circuit if the table has been migrated already
    result =
      execute(
        "SELECT data_type FROM information_schema.columns WHERE table_name = 'shelved_notifications' AND column_name = 'notification_id' LIMIT 1",
      )
    data_type = result[0]["data_type"]
    return if data_type.downcase == "bigint"

    min_id, max_id = execute("SELECT MIN(id), MAX(id) FROM shelved_notifications")[0].values
    batch_size = 10_000

    (min_id..max_id).step(batch_size) { |start_id| execute <<~SQL.squish } if min_id && max_id
        UPDATE shelved_notifications
        SET new_notification_id = notification_id
        WHERE id >= #{start_id} AND id < #{start_id + batch_size} AND notification_id != new_notification_id
      SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
