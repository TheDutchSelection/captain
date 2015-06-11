class RenameRedisKeyToRedisKey < ActiveRecord::Migration
  def change
    rename_column :apps, :etcd_key, :redis_key
    rename_column :zones, :etcd_key, :redis_key
  end
end
