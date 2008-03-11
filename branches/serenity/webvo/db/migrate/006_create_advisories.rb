class CreateAdvisories < ActiveRecord::Migration
  def self.up
    create_table :advisories do |t|
      t.string :program_id, :limit => 14, :null => false
      t.string :advisory, :limit => 30, :null => false
    end
    add_index :advisories, [:program_id]
  end

  def self.down
    drop_table :advisories
  end
end
