class CitationEnrichmentsController < ApplicationController
  # Requests metadata for the citation on one of the reader's notes. Citations
  # are shared, so the result appears on every note that cites the same DOI.
  def create
    note = current_user.notes.where.not(citation_doi: nil).find(params[:note_id])

    notice = if note.citation.request_enrichment
      "Fetching citation metadata."
    else
      "Citation metadata is already being fetched."
    end

    redirect_to note_path(note), status: :see_other, notice: notice
  end
end
