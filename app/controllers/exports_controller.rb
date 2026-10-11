class ExportsController < ApplicationController
  before_action :set_notebook

  def index
    @exports = @notebook.exports.with_attached_file.newest_first
  end

  def create
    @notebook.request_export
    redirect_to notebook_exports_path(@notebook), status: :see_other, notice: "Export queued."
  end

  private
    def set_notebook
      @notebook = current_user.notebooks.find(params[:notebook_id])
    end
end
