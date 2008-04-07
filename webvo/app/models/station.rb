class Station < ActiveRecord::Base
  has_many :mapped_stations
  has_many :lineups, :through => :mapped_stations
  has_many :schedules
  has_many :programs, :through => :schedules

  def display_name
    "#{self.callsign} #{self.fcc_channel_number}"
  end
end
