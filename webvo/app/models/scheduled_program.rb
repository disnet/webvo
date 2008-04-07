class ScheduledProgram < ActiveRecord::Base
  belongs_to :schedule

  def css_class
    'programme'
  end

  def method_missing(symbol_id, *args)
    begin
      super
    rescue NoMethodError
      self.schedule.__send__ symbol_id, *args
    end
  end
end
