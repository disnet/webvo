class CreateLineups < ActiveRecord::Migration
  def self.up
    create_table :lineups, :id => false do |t|
      t.string :name, :limit => 42, :null => false
      t.string :location, :limit => 28, :null => false
      t.string :device, :limit => 30
      t.string :type, :limit => 20, :null => false
      t.integer :postal_code
      t.string :id, :limit => 12, :null => false
    end
    add_index :lineups, [:id]
  end

  def self.down
    drop_table :lineups
  end
end
