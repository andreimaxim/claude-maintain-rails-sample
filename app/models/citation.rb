# A work identified by its DOI, shared by every reader who cites it. Readers'
# own annotations stay on their notes. Its metadata, and the state of the latest
# request for it, are shared too.
class Citation < ApplicationRecord
  has_many :notes, foreign_key: :citation_doi

  enum :enrichment_status, { pending: 0, completed: 1, failed: 2 }, prefix: :enrichment

  validates :doi, format: { with: %r{\A10\.\d{4,9}/\S+\z} }

  # Marks the citation pending and queues a metadata lookup, unless one is
  # already pending. Returns whether a lookup was queued. The job is queued under
  # the row lock, so a failed enqueue rolls back the pending state.
  def request_enrichment
    with_lock do
      if enrichment_pending?
        false
      else
        update!(enrichment_status: :pending, enrichment_error: nil)
        CitationEnrichmentJob.perform_later(self)
        true
      end
    end
  end

  # Asks the provider for this DOI's metadata. A permanent refusal marks the
  # enrichment failed; an unavailable provider raises so the job can retry.
  def enrich
    metadata = Provider.new.lookup(doi)
    record_enrichment(title: metadata.title, source_url: metadata.source_url, enrichment_status: :completed, enrichment_error: nil)
  rescue Provider::Error => error
    fail_enrichment(error.message)
  end

  def fail_enrichment(reason)
    record_enrichment(enrichment_status: :failed, enrichment_error: reason)
  end

  private
    # The job can load this citation before the request that queued it commits.
    # Taking the row lock waits for that commit and reloads, so the result is
    # written even when it equals the values loaded earlier.
    def record_enrichment(attributes)
      with_lock { update!(attributes) }
    end
end
