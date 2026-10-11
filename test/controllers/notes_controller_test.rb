require "test_helper"

class NotesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:reader) }

  test "lists the reader's notes newest first at both list paths" do
    [notes_path, journal_path].each do |path|
      get path

      assert_response :success
      assert_select ".note h2", count: 2
      assert_select ".note:first-child h2", "Montaigne on friendship"
      assert_select ".note h2", text: "Middlemarch private draft", count: 0
    end
  end

  test "renders an unbound search form" do
    get notes_path

    assert_select "form[role=search][action=?][method=get]", notes_path do
      assert_select "input[type=search][name=query]"
      assert_select "select[name=notebook_id] option", text: "Private research", count: 0
      assert_select "select[name=status] option[value=ready]", "Ready"
    end
  end

  test "filters by notebook, status, and title" do
    get notes_path, params: { notebook_id: notebooks(:novels).id }
    assert_select ".note h2", text: "Middlemarch chapter notes"
    assert_select ".note h2", text: "Montaigne on friendship", count: 0

    get notes_path, params: { status: "ready" }
    assert_select ".note h2", text: "Montaigne on friendship"
    assert_select ".note h2", text: "Middlemarch chapter notes", count: 0

    get notes_path, params: { query: "middlemarch" }
    assert_select ".note h2", count: 1
    assert_select ".note h2", text: "Middlemarch chapter notes"
  end

  test "shows an empty state when nothing matches" do
    get notes_path, params: { query: "Proust" }

    assert_select ".note", count: 0
    assert_select ".empty", "No notes match these filters."
  end

  test "pages through filtered notes newest first, keeping the filters and page size" do
    essays = notebooks(:essays)
    # Created newest first, so ID order is the reverse of the promised order.
    13.downto(1) { |n| essays.notes.create!(title: format("Reading %02d", n), status: "ready", created_at: Time.utc(2026, 10, 1, n)) }
    essays.notes.create!(title: "Reading draft", status: "draft", created_at: Time.utc(2026, 10, 2))
    notebooks(:novels).notes.create!(title: "Reading elsewhere", status: "ready", created_at: Time.utc(2026, 10, 2))
    filters = { "query" => "reading", "notebook_id" => essays.id.to_s, "status" => "ready", "per_page" => "5" }

    get notes_path, params: filters.merge("page" => "2")

    assert_equal ["Reading 08", "Reading 07", "Reading 06", "Reading 05", "Reading 04"], css_select(".note h2").map { _1.text.strip }
    assert_select ".range", "Displaying notes 6-10 of 13 in total"
    assert_select "select[name=per_page] option[selected]", "5"
    assert_equal filters.merge("page" => "1"), Rack::Utils.parse_query(URI(css_select("a[rel=prev]").first["href"]).query)
    next_url = URI(css_select("a[rel=next]").first["href"])
    assert_equal notes_path, next_url.path
    assert_equal filters.merge("page" => "3"), Rack::Utils.parse_query(next_url.query)

    get next_url.to_s

    assert_equal ["Reading 03", "Reading 02", "Reading 01"], css_select(".note h2").map { _1.text.strip }
    assert_select ".range", "Displaying notes 11-13 of 13 in total"
    assert_select "a[rel=prev]"
    assert_select "a[rel=next]", count: 0
  end

  test "invalid pages show the first page and page size is capped at 50" do
    50.times { |n| notebooks(:novels).notes.create!(title: format("Chapter %02d", n + 1), created_at: Time.utc(2026, 10, 1) + n.hours) }
    notebooks(:other_research).notes.create!(title: "Another reader's newest", created_at: Time.utc(2026, 11, 1))

    ["", "0", "-1", "two"].each do |page|
      get notes_path, params: { page: page }

      assert_response :success
      assert_select ".note", count: 10
      assert_select ".note:first-child h2", "Chapter 50"
      assert_select ".range", "Displaying notes 1-10 of 52 in total"
    end

    get notes_path, params: { per_page: "500", page: "2" }

    assert_equal ["Montaigne on friendship", "Middlemarch chapter notes"], css_select(".note h2").map { _1.text.strip }
    assert_select ".range", "Displaying notes 51-52 of 52 in total"
    assert_equal({ "per_page" => "50", "page" => "1" }, Rack::Utils.parse_query(URI(css_select("a[rel=prev]").first["href"]).query))

    get notes_path, params: { per_page: "50", page: "9" }

    assert_select ".range", "Displaying notes 51-52 of 52 in total"
  end

  test "creates a note in an owned notebook" do
    post notes_path, params: { note: { title: "Woolf on reading", body: "Common reader.", status: "ready", notebook_id: notebooks(:essays).id } }

    assert_redirected_to notes_path
    note = Note.find_by!(title: "Woolf on reading")
    assert_equal notebooks(:essays), note.notebook
    assert note.status_ready?
  end

  test "edits a note's rich body, tags, highlight, and status" do
    note = notes(:middlemarch)
    blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("page.png").open, filename: "page.png", content_type: "image/png")

    get edit_note_path(note)
    assert_select "input[type=radio][name='note[status]'][value=draft][checked]"
    assert_select "input[name='note[tag_list]'][value=?]", "Victorian, marriage"
    assert_select "input[type=radio][name='note[highlight_color]'][value=yellow][checked]"
    assert_select "input[type=hidden][name='note[body]'][value*=?]", "Dorothea and Casaubon."

    patch note_path(note), params: { note: {
      title: "Middlemarch, book one", status: "ready", notebook_id: note.notebook_id,
      tag_list: "provincial life, Victorian, , Victorian, reform", highlight_color: "green",
      body: %(<div>Lydgate arrives.</div><action-text-attachment sgid="#{blob.attachable_sgid}"></action-text-attachment>)
    } }

    assert_redirected_to notes_path
    note.reload
    assert_equal "Middlemarch, book one", note.title
    assert note.status_ready?
    assert_equal ["provincial life", "Victorian", "reform"], note.tags
    assert_equal({ "color" => "green" }, note.settings)
    assert_equal [blob], note.body.embeds.blobs

    get note_path(note)
    assert_select ".tags li", count: 3
    assert_select ".trix-content", text: /Lydgate arrives\./
    assert_select ".trix-content figure.attachment img[src*='page.png']"
  end

  test "rich text keeps collapsible excerpts and drops unsafe markup" do
    note = notes(:middlemarch)

    patch note_path(note), params: { note: { title: note.title, notebook_id: note.notebook_id,
      body: %(<details><summary>Prelude</summary><p>Saint Theresa</p></details><script>alert("x")</script><a href="javascript:alert(1)" onclick="steal()">Link</a>) } }
    get note_path(note)

    assert_select ".trix-content details summary", "Prelude"
    assert_select ".trix-content details p", "Saint Theresa"
    assert_select "main script", count: 0
    assert_select "main [onclick]", count: 0
    assert_select "main a[href^=javascript]", count: 0
  end

  test "a blank title re-renders the form with the submitted values" do
    note = notes(:middlemarch)

    patch note_path(note), params: { note: { title: "", body: "Revised body", tag_list: "reform, medicine", highlight_color: "blue", notebook_id: note.notebook_id } }

    assert_response :unprocessable_entity
    assert_select ".errors li", "Title can't be blank"
    assert_select "input[type=hidden][name='note[body]'][value=?]", "Revised body"
    assert_select "input[name='note[tag_list]'][value=?]", "reform, medicine"
    assert_select "input[type=radio][name='note[highlight_color]'][value=blue][checked]"
    note.reload
    assert_equal "Middlemarch chapter notes", note.title
    assert_equal ["Victorian", "marriage"], note.tags
  end

  test "deletes a note" do
    assert_difference -> { Note.count }, -1 do
      delete note_path(notes(:middlemarch))
    end

    assert_redirected_to notes_path
  end

  test "another reader's notes and notebooks cannot be reached" do
    other_note = notes(:other_secret)

    assert_raises(ActiveRecord::RecordNotFound) { get note_path(other_note) }
    assert_raises(ActiveRecord::RecordNotFound) { get edit_note_path(other_note) }
    assert_raises(ActiveRecord::RecordNotFound) do
      patch note_path(other_note), params: { note: { title: "Taken" } }
    end
    assert_raises(ActiveRecord::RecordNotFound) { delete note_path(other_note) }
    assert_raises(ActiveRecord::RecordNotFound) do
      get notes_path, params: { notebook_id: notebooks(:other_research).id }
    end

    assert_equal "Middlemarch private draft", other_note.reload.title
  end

  test "a note cannot be filed in another reader's notebook" do
    assert_no_difference -> { Note.count } do
      post notes_path, params: { note: { title: "Intruder", notebook_id: notebooks(:other_research).id } }
    end

    assert_response :unprocessable_entity
    assert_select ".errors li", "Notebook must exist"
  end
end
