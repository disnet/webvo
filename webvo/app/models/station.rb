class Station < ActiveRecord::Base
  has_many :lineup_stations
  has_many :lineups, :through => :lineup_stations
  has_many :schedules
  has_many :programs, :through => :schedules
end
