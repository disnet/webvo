class Lineup < ActiveRecord::Base
  has_many :lineup_stations
  has_many :stations, :through => :lineup_stations
end
