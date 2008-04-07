class CreateGenres < ActiveRecord::Migration
  def self.up
    create_table :genres do |t|
      t.string :program_id, :limit => 14, :null => false
      t.string :classification, :limit => 30, :null => false
      t.string :relevance, :limit => 1, :null => false
    end
    add_index :genres, [:program_id, :classification, :relevance]
    add_index :genres, [:classification]
  end

  def self.down
    drop_table :genres
  end
end
