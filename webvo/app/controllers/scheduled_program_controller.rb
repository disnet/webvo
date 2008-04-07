class ScheduledProgramController < ApplicationController

  def add
    @prog = Schedule.find params[:prog_id]
    @scheduled_program = ScheduledProgram.new :schedule_id => @prog.id 
    @scheduled_program.save

    respond_to do |format|
      format.html
      format.json
    end
  end

  def remove
    @scheduled_program = ScheduledProgram.find params[:prog_id]
    @scheduled_program.destroy

    respond_to do |format|
      format.html
      format.json
    end
  end

  def show
  end

  def list
    @scheduled_programs = ScheduledProgram.find:all

    respond_to do |format|
      format.html
      format.json
    end
  end
end
