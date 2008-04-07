class Schedule < ActiveRecord::Base
  belongs_to :program
  belongs_to :station
  has_one :recorded_program
  has_one :scheduled_program

  def filename
    #TODO: better formatting if no ep#
    name = [self.program.title,
            self.program.syndicated_episode_number,
            self.program.subtitle,
            self.time.strftime(DATE_TIME_FORMAT_FILENAME),
            self.station.fcc_channel_number
      ].delete_if{|val| val.nil?}.join("_-_")

    # is '-' a good replacement for the replaced chars in the filename?
    name.gsub(/\/|\\|:|\*|\?|"|<|>/,'-').gsub(/ /, "_")
  end
  
  def css_class
    'programme'
  end

  def time_readable
    self.time.strftime READABLE_TIME_FORMAT
  end

  def stop_time_readable
    self.stop_time.strftime READABLE_TIME_FORMAT
  end

  def method_missing(symbol_id, *args)
    begin
      super
    rescue NoMethodError
      if self.program.respond_to? symbol_id
        self.program.__send__ symbol_id, *args
      elsif self.station.respond_to? symbol_id
        self.station.__send__ symbol_id, *args
      else
        raise
      end
    end
  end
end
