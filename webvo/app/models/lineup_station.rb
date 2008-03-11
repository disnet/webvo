class LineupStation < ActiveRecord::Base
  belongs_to :station
  belongs_to :lineup
end
