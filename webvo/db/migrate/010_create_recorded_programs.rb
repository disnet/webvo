class CreateRecordedPrograms < ActiveRecord::Migration
  def self.up
    create_table :recorded_programs do |t|
      t.integer :schedule_id, :null => false
      t.string :filename

      t.timestamps
    end
  end

  def self.down
    drop_table :recorded_programs
  end
end
