require "test_helper"
require "open3"

class CitationEnrichmentsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:reader) }

  test "fetches a manually entered DOI's title and source URL, retrying one unavailable response" do
    note = notes(:middlemarch)
    patch note_path(note), params: { note: { title: note.title, doi: " 10.1000/eliot.1871 ", notebook_id: note.notebook_id } }
    assert_equal "10.1000/eliot.1871", note.reload.citation_doi

    requests = with_provider([503, {}], [200, { title: "Middlemarch", url: "https://example.org/works/middlemarch" }]) do
      post note_citation_enrichment_path(note)
      assert_redirected_to note_path(note)

      follow_redirect!
      assert_select "#citation_metadata", /Pending/
      assert_select "#citation_metadata button", count: 0

      perform_enqueued_jobs
    end

    assert_equal [["10.1000/eliot.1871", basic_auth("margin-notes", "local-only")]] * 2, requests
    citation = Citation.find("10.1000/eliot.1871")
    assert_equal ["completed", "Middlemarch", "https://example.org/works/middlemarch"],
      [citation.enrichment_status, citation.title, citation.source_url]

    get note_path(note)
    assert_select ".citation dd", "Middlemarch"
    assert_select ".citation a[href=?]", "https://example.org/works/middlemarch"
    assert_select "#citation_metadata", /Completed/

    # A worker can load the citation before the request that queued it commits.
    loaded_early = Citation.find("10.1000/eliot.1871")
    post note_citation_enrichment_path(note)
    with_provider([200, { title: "Middlemarch", url: "https://example.org/works/middlemarch" }]) { loaded_early.enrich }
    assert citation.reload.enrichment_completed?
  end

  test "provider credentials from the environment reach the server unchanged" do
    user, password = "00123", "sample: value # keep"

    requests = with_provider([200, { title: "Configured work", url: "https://example.org/configured" }]) do
      env = {
        "CITATION_PROVIDER_URL" => Rails.application.secrets.citation_provider[:url],
        "CITATION_PROVIDER_USER" => user,
        "CITATION_PROVIDER_PASSWORD" => password
      }
      # A fresh boot reads ENV instead of this process's cached settings.
      output, error, status = Open3.capture3(env, Rails.root.join("bin/rails").to_s, "runner",
        'puts Citation::Provider.new.lookup("10.1000/configured").title')

      assert status.success?, error
      assert_equal "Configured work\n", output
    end

    assert_equal [["10.1000/configured", basic_auth(user, password)]], requests
  end

  test "a provider that stays unavailable or refuses the request leaves a visible failure" do
    note = notes(:montaigne)
    note.update!(doi: "10.1000/essais")

    requests = with_provider([503, {}]) do
      perform_enqueued_jobs { post note_citation_enrichment_path(note) }
    end

    assert_equal 6, requests.size, "three job attempts, each retrying one 503"
    get note_path(note)
    assert_select "#citation_metadata", /Failed: The provider is unavailable \(HTTP 503\)/
    assert_select "#citation_metadata button", "Fetch again"

    requests = with_provider([401, {}]) do
      perform_enqueued_jobs { post note_citation_enrichment_path(note) }
    end

    assert_equal 1, requests.size
    assert_equal "The provider rejected the configured credentials (HTTP 401)", note.citation.reload.enrichment_error
    assert_nil note.citation.title

    with_provider([200, { title: "Essais", url: "javascript:alert(1)" }]) do
      perform_enqueued_jobs { post note_citation_enrichment_path(note) }
    end

    assert_equal ["failed", nil], [note.citation.reload.enrichment_status, note.citation.source_url]
    get note_path(note)
    assert_select ".citation a", count: 0
  end

  test "readers can only request metadata through their own cited notes" do
    other_note = notes(:other_secret)
    other_note.update!(doi: "10.1000/private")

    assert_raises(ActiveRecord::RecordNotFound) { post note_citation_enrichment_path(other_note) }
    assert_raises(ActiveRecord::RecordNotFound) { post note_citation_enrichment_path(notes(:montaigne)) }

    assert_no_enqueued_jobs
    assert_nil other_note.citation.reload.enrichment_status
  end

  private
    # Serves the given [status, JSON] responses in order from a loopback HTTP
    # server, repeating the last, and returns each request's DOI and
    # Authorization header.
    def with_provider(*responses)
      requests = []
      app = lambda do |env|
        requests << [Rack::Request.new(env).params["doi"], env["HTTP_AUTHORIZATION"]]
        status, body = responses.size > 1 ? responses.shift : responses.first
        [status, { "Content-Type" => "application/json" }, [body.to_json]]
      end

      server = Puma::Server.new(app, Puma::Events.strings)
      server.add_tcp_listener("127.0.0.1", 0)
      server.run

      settings = Rails.application.secrets.citation_provider
      Rails.application.secrets.citation_provider = settings.merge(url: "http://127.0.0.1:#{server.connected_ports.first}")
      yield
      requests
    ensure
      Rails.application.secrets.citation_provider = settings if settings
      server&.stop(true)
    end

    def basic_auth(user, password)
      "Basic #{Base64.strict_encode64("#{user}:#{password}")}"
    end
end
