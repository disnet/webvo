class Lineup < ActiveRecord::Base
  has_many :mapped_stations
  has_many :stations, :through => :mapped_stations
  validates_presence_of :name, :location, :media_type, :id
end
