class DigestJob < ApplicationJob
  queue_as :default

  # The request time arrives in the worker's time zone, and the completion as
  # the decimal string it was stored as in the queue. See User#request_digest.
  def perform(reader, requested_at, completion)
    DigestMailer.with(reader: reader, requested_at: requested_at, completion: completion).daily_digest.deliver_now
  end
end
