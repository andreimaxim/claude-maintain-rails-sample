class NotebooksController < ApplicationController
  before_action :set_notebook, only: [:edit, :update]

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

  def edit
  end

  def update
    if @notebook.update(notebook_params)
      redirect_to notebooks_path, notice: "Notebook settings saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_notebook
      @notebook = current_user.notebooks.find(params[:id])
    end

    # The settings form resubmits the slug, which stays read-only after creation.
    def notebook_params
      params.require(:notebook).permit(:name, :slug, :export_heading)
    end
end
