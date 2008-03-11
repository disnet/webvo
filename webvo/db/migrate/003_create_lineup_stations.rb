class CreateLineupStations < ActiveRecord::Migration
  def self.up
    create_table :lineup_stations, :id => false do |t|
      t.string :lineup_id, :limit => 12, :null => false
      t.integer :station_id, :null => false
      t.string :channel, :limit => 5, :null => false
      t.integer :channel_minor
      t.date :from
      t.date :to
    end
    add_index :lineup_stations, [:lineup_id]
    add_index :lineup_stations, [:station_id]
  end

  def self.down
    drop_table :lineup_stations
  end
end
