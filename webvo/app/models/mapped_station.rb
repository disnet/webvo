class MappedStation < ActiveRecord::Base
  belongs_to :station
  belongs_to :lineup
end
