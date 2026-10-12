class User < ApplicationRecord
  # Keep digest reservations past the end of their UTC day.
  DIGEST_RESERVATIONS_KEPT_FOR = 2.days

  has_secure_password

  has_many :notebooks, dependent: :destroy
  has_many :notes, through: :notebooks

  before_validation { self.email = email.to_s.strip.downcase }

  validates :email, presence: true, uniqueness: true
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  def self.authenticate(email, password)
    find_by(email: email.to_s.strip.downcase)&.authenticate(password)
  end

  # Reads a date and time the reader entered, such as "2026-10-31T09:00", in
  # their time zone. Returns nil when it is blank or not a valid time.
  def local_time(text)
    Time.find_zone!(time_zone).iso8601(text.to_s) if text.present?
  rescue ArgumentError
    nil
  end

  # Queues an email digest of ready notes updated today (UTC), unless the reader
  # has already requested one for that UTC day. Returns whether a digest was queued.
  #
  # A Redis set of reader IDs for each day holds the reservations. If the job
  # cannot be queued, the reservation is released and the error raised, so the
  # reader can ask again. This prevents repeated requests, not repeated
  # deliveries: a job that Sidekiq retries can send its digest more than once.
  def request_digest
    requested_at = Time.current.in_time_zone(time_zone)
    key = "digest_requests:#{requested_at.utc.to_date.iso8601}"

    if Sidekiq.redis { |redis| redis.sadd(key, id) }
      begin
        Sidekiq.redis { |redis| redis.expire(key, DIGEST_RESERVATIONS_KEPT_FOR.to_i) }
        DigestJob.perform_later(self, requested_at, reading_completion)
      rescue StandardError
        Sidekiq.redis { |redis| redis.srem(key, id) }
        raise
      end

      true
    else
      false
    end
  end

  # The share of the reader's notes that are ready, from 0 to 1.
  def reading_completion
    total = notes.count
    total.zero? ? BigDecimal("0") : (BigDecimal(notes.status_ready.count) / total).round(4)
  end
end
