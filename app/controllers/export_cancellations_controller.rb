class ExportCancellationsController < ApplicationController
  def create
    notebook = current_user.notebooks.find(params[:notebook_id])
    export = notebook.exports.find(params[:export_id])

    notice = export.cancel ? "Export cancelled." : "This export has already finished."
    redirect_to notebook_exports_path(notebook), status: :see_other, notice: notice
  end
end
