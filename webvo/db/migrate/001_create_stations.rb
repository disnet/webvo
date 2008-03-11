class CreateStations < ActiveRecord::Migration
  def self.up
    create_table :stations, :id => false do |t|
      t.integer :id, :null => false
      t.string :callsign, :limit => 10, :null => false
      t.string :name, :limit => 40, :null => false
      t.string :affiliate, :limit => 25
      t.integer :fcc_channel_number
    end
    add_index :stations, [:id]
  end

  def self.down
    drop_table :stations
  end
end
