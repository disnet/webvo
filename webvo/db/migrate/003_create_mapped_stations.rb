class CreateMappedStations < ActiveRecord::Migration
  def self.up
    create_table :mapped_stations do |t|
      t.string :lineup_id, :limit => 12, :null => false
      t.integer :station_id, :null => false
      t.string :channel, :limit => 5, :null => false
      t.integer :channel_minor
      t.date :from
      t.date :to
    end
    add_index :mapped_stations, [:lineup_id, :station_id], { :unique => true }
    add_index :mapped_stations, [:station_id]
  end

  def self.down
    drop_table :mapped_stations
  end
end
