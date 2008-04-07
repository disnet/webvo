class RecordedProgramController < ApplicationController

  def add
  end

  def remove
    @recorded_program = ScheduledProgram.find params[:prog_id]
    @recorded_program.destroy

    respond_to do |format|
      format.html
      format.json
    end
  end

  def show
  end

  def list
    # this should be sorted, making the assumption they are added by date
    @recorded_programs = RecordedProgram.find:all

    respond_to do |format|
      format.html
      format.json
    end
  end
end
