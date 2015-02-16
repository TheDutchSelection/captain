class CreateZones < ActiveRecord::Migration
  def change
    create_table :zones do |t|
      t.string :name, limit: 255, unique: true, null: false
      t.string :etcd_key, limit: 255, unique: true, null: false

      t.timestamps null: false
    end
  end
end
