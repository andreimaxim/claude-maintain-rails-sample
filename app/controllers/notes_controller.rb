class NotesController < ApplicationController
  before_action :set_note, only: [:show, :edit, :update, :destroy]
  before_action :set_notebooks, except: [:show, :destroy]

  def index
    @notes = current_user.notes.includes(:notebook).with_rich_text_body.newest_first

    if params[:notebook_id].present?
      @notebook = current_user.notebooks.find(params[:notebook_id])
      @notes = @notes.where(notebooks: @notebook)
    end

    @notes = @notes.where(status: params[:status]) if Note.statuses.key?(params[:status])
    @notes = @notes.titled_like(params[:query]) if params[:query].present?
  end

  def new
    @note = Note.new
  end

  def create
    @note = Note.new(note_params)
    @note.notebook = owned_notebook

    if @note.save
      redirect_to notes_path, notice: "Note created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    @note.assign_attributes(note_params)
    @note.notebook = owned_notebook

    if @note.save
      redirect_to notes_path, notice: "Note updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @note.destroy
    redirect_to notes_path, status: :see_other, notice: "Note deleted."
  end

  private
    def set_note
      @note = current_user.notes.find(params[:id])
    end

    def set_notebooks
      @notebooks = current_user.notebooks.order(:name, :id)
    end

    def note_params
      params.require(:note).permit(:title, :body, :status, :tag_list, :highlight_color)
    end

    def owned_notebook
      current_user.notebooks.find_by(id: params.dig(:note, :notebook_id))
    end
end
