class ImportsController < ApplicationController
  before_action :set_notebook

  def new
    @import = @notebook.imports.new
  end

  # Applies a previewed CSV. The rows are read and validated again here.
  def create
    @import = @notebook.imports.new(import_params)

    if @import.apply
      redirect_to notebook_import_path(@notebook, @import), status: :see_other,
        notice: "Imported #{helpers.pluralize(@import.rows.size, "note")}."
    elsif @import.errors.any?
      render :new, status: :unprocessable_entity
    else
      @import.preview
      render :preview, status: :unprocessable_entity
    end
  end

  def show
    @import = @notebook.imports.find(params[:id])

    respond_to do |format|
      format.html { @notes = @import.notes.includes(:citation).order(:id) }
      format.csv { send_data @import.receipt, type: :csv, filename: "import-#{@import.id}-receipt.csv" }
    end
  end

  private
    def set_notebook
      @notebook = current_user.notebooks.find(params[:notebook_id])
    end

    def import_params
      params.fetch(:import, {}).permit(:csv)
    end
end
