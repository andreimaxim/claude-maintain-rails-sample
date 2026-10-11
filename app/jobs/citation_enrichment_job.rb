class CitationEnrichmentJob < ApplicationJob
  queue_as :default

  # Three attempts in all, each of which may already have retried once on 503.
  # After the last, the failure is recorded rather than handed to the queue's
  # own retries.
  retry_on Citation::Provider::Unavailable, wait: :exponentially_longer, attempts: 3 do |job, error|
    job.arguments.first.fail_enrichment(error.message)
  end

  def perform(citation)
    citation.enrich
  end
end
