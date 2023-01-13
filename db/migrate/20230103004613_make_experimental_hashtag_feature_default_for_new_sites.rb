# frozen_string_literal: true

class MakeExperimentalHashtagFeatureDefaultForNewSites < ActiveRecord::Migration[7.0]
  def up
    result = execute <<~SQL
      SELECT created_at
      FROM schema_migration_details
      ORDER BY created_at
      LIMIT 1
    SQL

    # keep enable_experimental_hashtag_autocomplete disabled for for existing sites
    if result.first['created_at'].to_datetime < 1.hour.ago
      execute <<~SQL
        INSERT INTO site_settings (name, data_type, value, created_at, updated_at)
        VALUES ('enable_experimental_hashtag_autocomplete', 5, 'f', now(), now())
        ON CONFLICT DO NOTHING
      SQL
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
