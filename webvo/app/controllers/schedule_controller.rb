class ScheduleController < ApplicationController

  def show
  end

  def list
    # fix this, i.e. make it actually search for the requested shows/schedules
    hours = 3
    @start = params[:start_date_time]
    unless @start.nil?
      @start = Time.parse @start
    else
      @start = Time.now
    end
    @stop = @start + 3 * 60 * 60
    
    # params for searching are:
    #  start before section end
    #  end after section start

    @schedules = Schedule.find :all, 
      :conditions => ["time < ? and stop_time > ?", @stop, @start]
    @schedules_by_station = Hash.new
    @schedules.each do |sched|
      key = sched.station
      unless @schedules_by_station.has_key? key
        @schedules_by_station[key] = Array.new
      end
      @schedules_by_station[key] = @schedules_by_station[key] << sched
    end

    @schedules_by_station.each do |key,value|
      value.sort! {|a,b| a.time <=> b.time}
    end

#    @schedules.sort! do |a,b|
#      if a.fcc_channel_number < b.fcc_channel_number
#        -1
#      elsif a.fcc_channel_number > b.fcc_channel_number
#        1
#      else
#        a.time <=> b.time
#      end
#    end

    respond_to do |format|
      format.html
      format.json
    end
  end

  def search
    @schedules = Schedule.find :all, 
      :conditions => ["stop_time > ?", Time.now]

    respond_to do |format|
      format.html
      format.json
    end
  end

  #
  # should this really go here? everything is pretty much schedule related
  #  except for the hd stats and (kinda) the server datetime
  #  ... actually, the hd space is not currently used
  #
  def stats
    first = Schedule.find :first, :order => 'time asc'
    last = Schedule.find :first, :order => 'stop_time desc'

    # could xmlschema be more of a 'view' thing?
    @program_date_range = {:start => first.time.xmlschema,
      :stop => last.stop_time.xmlschema }
    
    @datetime = Time.now.xmlschema

    #TODO: add support for returning currently recording show?

    respond_to do |format|
      format.html
      format.json
    end
  end
end
