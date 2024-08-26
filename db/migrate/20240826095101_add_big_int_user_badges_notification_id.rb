# frozen_string_literal: true

class AddBigIntUserBadgesNotificationId < ActiveRecord::Migration[7.0]
  def up
    # Short-circuit if the table has been migrated already
    result =
      execute(
        "SELECT data_type FROM information_schema.columns WHERE table_name = 'user_badges' AND column_name = 'notification_id' LIMIT 1",
      )
    data_type = result[0]["data_type"]
    return if data_type.downcase == "bigint"

    # Create new column
    execute "ALTER TABLE user_badges ADD COLUMN new_notification_id BIGINT"

    # Mirror new `notification_id` values to `new_notification_id`
    execute <<~SQL.squish
      CREATE FUNCTION mirror_user_badges_notification_id()
      RETURNS trigger AS
      $$
      BEGIN
        NEW.new_notification_id = NEW.notification_id;
        RETURN NEW;
      END;
      $$
      LANGUAGE plpgsql
    SQL

    execute <<~SQL.squish
      CREATE TRIGGER user_badges_new_notification_id_trigger BEFORE INSERT ON user_badges
      FOR EACH ROW EXECUTE PROCEDURE mirror_user_badges_notification_id()
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
