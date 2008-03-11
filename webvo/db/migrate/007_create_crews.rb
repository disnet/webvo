class CreateCrews < ActiveRecord::Migration
  def self.up
    create_table :crews do |t|
      t.string :program_id, :limit => 14, :null => false
      t.string :role, :limit => 30
      t.string :given_name, :limit => 20
      t.string :surname, :limit => 20, :null => false
    end
    add_index :crews, [:program_id]
  end

  def self.down
    drop_table :crews
  end
end
