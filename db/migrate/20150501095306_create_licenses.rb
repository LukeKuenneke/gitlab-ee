class CreateLicenses < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :licenses do |t|
      t.text :data, null: false

      t.timestamps
    end
  end
end
