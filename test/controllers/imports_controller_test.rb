require "test_helper"

class ImportsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:reader) }

  test "previews a CSV without saving, then imports every row and offers a receipt" do
    notebook = notebooks(:essays)
    csv = <<~CSV
      title,body_html,doi,annotation,reminder_epoch
      On idleness,<p>Idle <b>minds</b></p>,10.1000/Essays.1,Read twice,1767225600

      "Of experience","<p>Long
      essay</p>",10.1000/Essays.1,Compare with Bacon,
    CSV

    assert_no_changes -> { record_counts } do
      post notebook_import_preview_path(notebook), params: { import: { file: upload(csv) } }
    end

    assert_response :success
    assert_select "#line_2 h2", "Line 2: On idleness"
    assert_select "#line_2 dd", "Read twice"
    assert_select "#line_4 h2", "Line 4: Of experience"
    assert_select "#line_4 dd", "Compare with Bacon"
    assert_select "#line_2 time[datetime=?]", "2026-01-01T00:00:00Z"
    csv_field = css_select("input[type=hidden][name='import[csv]']").first["value"]

    assert_difference -> { Note.count } => 2, -> { Citation.count } => 1, -> { Import.count } => 1 do
      post notebook_imports_path(notebook), params: { import: { csv: csv_field } }
    end

    import = Import.last
    assert_redirected_to notebook_import_path(notebook, import)
    idleness, experience = import.notes.order(:id)
    assert_equal [notebook, notebook], [idleness.notebook, experience.notebook]
    assert_equal ["Read twice", 1767225600], [idleness.annotation, idleness.reminder_epoch]
    assert_equal ["Compare with Bacon", nil], [experience.annotation, experience.reminder_epoch]

    get note_path(idleness)
    assert_select ".trix-content b", "minds"
    assert_select ".citation dd", text: "Read twice"

    get notebook_import_path(notebook, import, format: :csv)
    assert_equal "text/csv", response.media_type
    assert_equal "title,doi\nOn idleness,10.1000/Essays.1\nOf experience,10.1000/Essays.1\n", response.body
  end

  test "invalid rows are shown with their errors, and applying them saves nothing" do
    notebook = notebooks(:novels)
    csv = <<~CSV
      title,body_html,doi,annotation,reminder_epoch
      Adam Bede,<p>Hayslope</p>,10.1000/bede,First reading,
      ,<p>Untitled</p>,not-a-doi,Second reading,tomorrow
    CSV

    post notebook_import_preview_path(notebook), params: { import: { file: upload(csv) } }

    assert_response :unprocessable_entity
    assert_select "#line_3 .row-errors li", "Title can't be blank"
    assert_select "#line_3 .row-errors li", "DOI is invalid"
    assert_select "#line_3 .row-errors li", "Reminder epoch is not a number"
    assert_select "#line_3 dd", "Second reading"
    assert_select "input[name='import[csv]']", count: 0

    assert_no_changes -> { record_counts } do
      post notebook_imports_path(notebook), params: { import: { csv: csv } }
    end

    assert_response :unprocessable_entity
    assert_select "#line_2 .row-errors", count: 0
    assert_select "#line_3 .row-errors li", "Title can't be blank"
    assert_nil Note.find_by(title: "Adam Bede")
  end

  test "rejects a missing CSV or one without the documented header row" do
    post notebook_import_preview_path(notebooks(:novels)), params: { import: { file: upload("name,doi\nAdam Bede,10.1000/bede\n") } }

    assert_response :unprocessable_entity
    assert_select ".errors li", "CSV file must start with the header row title,body_html,doi,annotation,reminder_epoch"

    post notebook_imports_path(notebooks(:novels)), params: { import: { csv: "" } }

    assert_response :unprocessable_entity
    assert_select ".errors li", "CSV file can't be blank"
  end

  test "another reader's notebook cannot receive or reveal imports" do
    other_notebook = notebooks(:other_research)
    other_import = other_notebook.imports.create!(csv: "title,body_html,doi,annotation,reminder_epoch\nPrivate,,,,\n")
    csv = "title,body_html,doi,annotation,reminder_epoch\nIntruder,,,,\n"

    assert_no_changes -> { record_counts } do
      assert_raises(ActiveRecord::RecordNotFound) { get new_notebook_import_path(other_notebook) }
      assert_raises(ActiveRecord::RecordNotFound) do
        post notebook_import_preview_path(other_notebook), params: { import: { file: upload(csv) } }
      end
      assert_raises(ActiveRecord::RecordNotFound) do
        post notebook_imports_path(other_notebook), params: { import: { csv: csv } }
      end
    end
    assert_raises(ActiveRecord::RecordNotFound) { get notebook_import_path(other_notebook, other_import, format: :csv) }
    assert_raises(ActiveRecord::RecordNotFound) { get notebook_import_path(notebooks(:novels), other_import) }
  end

  private
    def record_counts
      [Import.count, Note.count, Citation.count, ActionText::RichText.count]
    end

    def upload(csv)
      Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "notes.csv")
    end
end
