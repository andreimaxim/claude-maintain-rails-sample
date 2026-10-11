class NotebooksController < ApplicationController
  def index
    @notebooks = current_user.notebooks.order(:name, :id)
  end

  def new
    @notebook = current_user.notebooks.new
  end

  def create
    @notebook = current_user.notebooks.new(notebook_params)

    if @notebook.save
      redirect_to notebooks_path, notice: "Notebook created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def notebook_params
      params.require(:notebook).permit(:name)
    end
end
