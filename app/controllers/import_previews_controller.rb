class ImportPreviewsController < ApplicationController
  before_action :set_notebook

  # Reads the uploaded CSV and shows what applying it would import. Saves nothing.
  def create
    @import = @notebook.imports.new(import_params)

    if @import.preview
      render "imports/preview"
    elsif @import.errors.any?
      render "imports/new", status: :unprocessable_entity
    else
      render "imports/preview", status: :unprocessable_entity
    end
  end

  private
    def set_notebook
      @notebook = current_user.notebooks.find(params[:notebook_id])
    end

    def import_params
      params.fetch(:import, {}).permit(:file)
    end
end
