class AddMirrorMaxRetryCountToApplicationSetting < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :application_settings,
                            :mirror_max_retry_count,
                            :integer,
                            default: 14,
                            allow_null: false

    ApplicationSetting.expire
  end

  def down
    remove_column :application_settings, :mirror_max_retry_count
  end
end
