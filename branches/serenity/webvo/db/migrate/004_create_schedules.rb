class CreateSchedules < ActiveRecord::Migration
  def self.up
    create_table :schedules do |t|
      t.string :program_id, :limit => 14, :null => false
      t.integer :station_id, :null => false
      t.timestamp :time, :null => false
      t.string :duration, :limit => 8, :null => false
      t.boolean :new, :default => 0
      t.boolean :stereo, :default => 0
      t.boolean :subtitled, :default => 0
      t.boolean :hdtv, :default => 0
      t.boolean :close_captioned, :default => 0
      t.string :tv_rating, :limit => 5
      t.string :part_number, :limit => 2
      t.string :part_total, :limit => 2
    end
    add_index :schedules, [:program_id]
    add_index :schedules, [:station_id]
    add_index :schedules, [:time]
  end

  def self.down
    drop_table :schedules
  end
end
