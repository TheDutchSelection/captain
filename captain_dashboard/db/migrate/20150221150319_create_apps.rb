class CreateApps < ActiveRecord::Migration
  def change
    create_table :apps do |t|
      t.string :name, limit: 255, unique: true, null: false
      t.string :etcd_key, limit: 255, unique: true, null: false

      t.timestamps null: false
    end

    create_table :apps_zones, id: false do |t|
      t.belongs_to :app, index: true
      t.belongs_to :zone, index: true
    end
  end
end
