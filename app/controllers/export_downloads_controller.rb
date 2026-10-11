class ExportDownloadsController < ApplicationController
  # Ownership and expiry are checked on every request, before any conditional
  # response, rather than trusting the cached indicator on the exports page.
  def show
    notebook = current_user.notebooks.find(params[:notebook_id])
    export = notebook.exports.find(params[:export_id])

    if export.downloadable?
      blob = export.file.blob

      if stale?(etag: blob.checksum, last_modified: blob.created_at)
        send_data blob.download, filename: blob.filename.to_s, type: "text/markdown; charset=utf-8"
      end
    else
      redirect_to notebook_exports_path(notebook), alert: "That export is not available to download."
    end
  end
end
