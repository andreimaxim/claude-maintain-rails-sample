require "test_helper"

class ExportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    ExportJob.clear
    sign_in_as users(:reader)
  end

  test "a reader exports a notebook as Markdown and downloads it until it expires" do
    notebook = notebooks(:novels)
    notebook.update!(export_heading: "Victorian reading")
    notebook.notes.create!(title: "Daniel Deronda", body: "<div>Gwendolen at the <strong>roulette</strong> table.</div>",
      created_at: Time.utc(2026, 9, 5))

    post notebook_exports_path(notebook)
    assert_redirected_to notebook_exports_path(notebook)

    export = notebook.exports.sole
    job = ExportJob.jobs.sole
    assert_equal [export.id, { "format" => "markdown" }], job["args"]
    assert_equal job["jid"], export.job_id

    get notebook_exports_path(notebook)
    assert_select "##{dom_id(export)}", /Queued/
    assert_select "##{dom_id(export)} code", export.job_id
    assert_select "##{dom_id(export)} button", "Cancel export"

    completed_at = Time.utc(2026, 10, 11, 9)
    travel_to(completed_at) do
      ExportJob.drain

      get notebook_exports_path(notebook)
      assert_select "##{dom_id(export)}", /Complete\s+· 2 of 2 notes processed/
      assert_select "##{dom_id(export)} button", count: 0
      assert_select "##{dom_id(export)} a[href=?]", notebook_export_download_path(notebook, export), "Download novels.md"
    end

    travel_to(completed_at + 24.hours - 1.second) do
      get notebook_export_download_path(notebook, export)
      assert_response :success
      assert_equal "# Victorian reading\n\n## Middlemarch chapter notes\n\nDorothea and Casaubon.\n\n## Daniel Deronda\n\nGwendolen at the roulette table.\n",
        response.body
      assert_equal "text/markdown; charset=utf-8", response.content_type
      assert_match(/attachment; filename="novels.md"/, response.headers["Content-Disposition"])
      etag, last_modified = response.headers.values_at("ETag", "Last-Modified")
      assert last_modified

      get notebook_export_download_path(notebook, export), headers: { "If-None-Match" => etag }
      assert_response :not_modified
      assert_empty response.body

      travel 1.second
      get notebook_export_download_path(notebook, export), headers: { "If-None-Match" => etag, "If-Modified-Since" => last_modified }
      assert_redirected_to notebook_exports_path(notebook)
      assert_equal "That export is not available to download.", flash[:alert]
    end
  end

  test "the cached availability indicator does not authorize a download" do
    store, caching = ActionController::Base.cache_store, ActionController::Base.perform_caching
    ActionController::Base.cache_store = ActiveSupport::Cache::MemoryStore.new
    ActionController::Base.perform_caching = true

    notebook = notebooks(:novels)
    export = notebook.request_export
    travel_to(Time.utc(2026, 10, 11, 9)) { ExportJob.drain }
    download_link = "##{dom_id(export)} a[href=?]"

    travel_to Time.utc(2026, 10, 11, 10) do
      get notebook_exports_path(notebook)
      assert_select download_link, notebook_export_download_path(notebook, export)

      # Expire the export without changing its cache key, as if the cached
      # indicator had outlived the authoritative deadline.
      export.update_columns(expires_at: 1.minute.ago)

      get notebook_exports_path(notebook)
      assert_select download_link, notebook_export_download_path(notebook, export)

      get notebook_export_download_path(notebook, export)
      assert_redirected_to notebook_exports_path(notebook)
    end

    # The indicator was cached until the original deadline; read it again after that.
    travel_to Time.utc(2026, 10, 12, 9, 1) do
      get notebook_exports_path(notebook)
      assert_select "##{dom_id(export)} a", count: 0
      assert_select "##{dom_id(export)} .availability", /Expired/
    end
  ensure
    ActionController::Base.cache_store, ActionController::Base.perform_caching = store, caching
  end

  test "cancelling a queued export means the worker writes no file" do
    notebook = notebooks(:novels)
    post notebook_exports_path(notebook)
    export = notebook.exports.sole

    post notebook_export_cancellation_path(notebook, export)
    assert_redirected_to notebook_exports_path(notebook)
    assert_equal "Export cancelled.", flash[:notice]

    ExportJob.drain

    export.reload
    assert export.cancelled?
    assert_equal [0, nil], [export.processed_notes_count, export.total_notes_count]
    assert_not export.file.attached?

    get notebook_exports_path(notebook)
    assert_select "##{dom_id(export)}", /Cancelled/
    assert_select "##{dom_id(export)} button", count: 0

    get notebook_export_download_path(notebook, export)
    assert_redirected_to notebook_exports_path(notebook)
  end

  test "another reader's exports cannot be requested, seen, cancelled, or downloaded" do
    other_notebook = notebooks(:other_research)
    finished = other_notebook.exports.create!.tap(&:generate)
    queued = other_notebook.exports.create!

    assert_raises(ActiveRecord::RecordNotFound) { get notebook_exports_path(other_notebook) }
    assert_raises(ActiveRecord::RecordNotFound) { post notebook_exports_path(other_notebook) }
    assert_raises(ActiveRecord::RecordNotFound) { post notebook_export_cancellation_path(other_notebook, queued) }
    assert_raises(ActiveRecord::RecordNotFound) { get notebook_export_download_path(other_notebook, finished) }
    assert_raises(ActiveRecord::RecordNotFound) { get notebook_export_download_path(notebooks(:novels), finished) }

    assert_equal 2, other_notebook.exports.count
    assert_empty ExportJob.jobs
    assert queued.reload.queued?
  end
end
