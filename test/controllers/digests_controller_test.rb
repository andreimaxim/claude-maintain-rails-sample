require "test_helper"
require "minitest/mock"

class DigestsControllerTest < ActionDispatch::IntegrationTest
  test "a reader can request one digest per UTC day, listing ready notes updated that day" do
    release_digest_reservations "2026-10-04", "2026-10-05", "2026-10-06"
    users(:reader).update!(time_zone: "Eastern Time (US & Canada)")
    notes(:montaigne).update_columns(updated_at: Time.utc(2026, 10, 4, 16))

    travel_to Time.utc(2026, 10, 5, 3, 30) do
      notebooks(:essays).notes.create!(title: "Bacon on studies", status: :ready)
      notebooks(:novels).notes.create!(title: "Adam Bede, unfinished", status: :draft)

      sign_in_as users(:reader)
      post digest_path
      assert_redirected_to notes_path
      assert_equal "Today's reading digest is on its way.", flash[:notice]

      travel 9.hours + 30.minutes
      post digest_path
      assert_equal "You have already requested today's reading digest.", flash[:notice]

      sign_in_as users(:other_reader)
      post digest_path
      assert_equal "Today's reading digest is on its way.", flash[:notice]
    end

    assert_equal [users(:reader), users(:other_reader)], enqueued_jobs.map { |job| GlobalID::Locator.locate(job[:args].first["_aj_globalid"]) }
    assert_equal "2026-10-04T23:30:00.000000000-04:00", enqueued_jobs.first[:args].second["value"], "the job carries the reader's local time"

    perform_enqueued_jobs
    mail = ActionMailer::Base.deliveries.find { |delivery| delivery.to == ["reader@example.com"] }
    assert_equal "Your reading digest for October 05, 2026", mail.subject
    assert_includes mail.body.to_s, "- Bacon on studies (Essays)"
    assert_not_includes mail.body.to_s, "Montaigne"
    assert_not_includes mail.body.to_s, "Adam Bede"
    assert_includes mail.body.to_s, "50% of your notes were ready"

    travel_to Time.utc(2026, 10, 6, 0, 30) do
      sign_in_as users(:reader)
      assert_enqueued_jobs(1, only: DigestJob) { post digest_path }
    end
  end

  test "a digest request is released when its job cannot be queued" do
    release_digest_reservations "2026-10-07"
    sign_in_as users(:reader)

    travel_to Time.utc(2026, 10, 7, 12) do
      DigestJob.stub(:perform_later, ->(*) { raise Redis::CannotConnectError }) do
        assert_raises(Redis::CannotConnectError) { post digest_path }
      end
      assert_no_enqueued_jobs

      post digest_path
      assert_equal "Today's reading digest is on its way.", flash[:notice]
      assert_enqueued_jobs 1, only: DigestJob
    end
  end

  private
    # Reservations are kept in Redis, outside the test database's transactions.
    def release_digest_reservations(*dates)
      readers = [users(:reader).id, users(:other_reader).id]
      Sidekiq.redis { |redis| dates.each { |date| redis.srem("digest_requests:#{date}", readers) } }
    end
end
