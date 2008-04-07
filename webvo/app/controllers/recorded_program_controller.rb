class RecordedProgramController < ApplicationController

  def add
  end

  def remove
  end

  def show
  end

  def list
    @recorded_programs = RecordedProgram.find:all

    respond_to do |format|
      format.html
      format.json
    end
  end
end
