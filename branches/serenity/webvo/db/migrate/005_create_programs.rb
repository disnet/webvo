class CreatePrograms < ActiveRecord::Migration
  def self.up
    create_table :programs, :id => false do |t|
      t.string :id, :limit => 14, :null => false
      t.string :series, :limit => 12
      t.string :title, :limit => 120, :null => false
      t.string :subtitle, :limit => 150
      t.string :description, :limit => 255
      t.string :mpaa_rating, :limit => 5
      t.string :star_rating, :limit => 5
      t.string :runtime, :limit => 8
      t.string :year, :limit => 4
      t.string :show_type, :limit => 30
      t.string :color_code, :limit => 20
      t.date :original_air_date
      t.string :syndicated_episode_number, :limit => 20
    end
    add_index :programs, [:id]
    add_index :programs, [:title]
    add_index :programs, [:subtitle]
  end

  def self.down
    drop_table :programs
  end
end
