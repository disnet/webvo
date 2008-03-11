class Program < ActiveRecord::Base
  has_many :schedules
  has_many :stations, :through => :schedules
  has_many :advisories
  has_many :crews
  has_many :genres
end
