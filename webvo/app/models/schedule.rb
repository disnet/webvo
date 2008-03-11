class Schedule < ActiveRecord::Base
  belongs_to :program
  belongs_to :station
end
