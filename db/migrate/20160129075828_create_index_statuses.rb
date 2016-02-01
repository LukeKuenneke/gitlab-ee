class CreateIndexStatuses < ActiveRecord::Migration
  def change
    create_table :index_statuses do |t|
      t.integer :project_id
      t.datetime :indexed_at
      t.text :note
      t.string :last_commit

      t.timestamps null: false
    end

    add_index :index_statuses, :project_id
  end
end
