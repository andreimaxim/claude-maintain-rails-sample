require "test_helper"

class NotebooksControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:reader) }

  test "lists only the reader's notebooks" do
    get notebooks_path

    assert_select "li a", text: "Novels"
    assert_select "li a", text: "Private research", count: 0
  end

  test "creates a notebook owned by the reader with a slug from its name" do
    assert_difference -> { users(:reader).notebooks.count } do
      post notebooks_path, params: { notebook: { name: "Poetry & Verse", slug: "chosen" } }
    end

    assert_redirected_to notebooks_path
    assert_equal "poetry-verse", users(:reader).notebooks.find_by!(name: "Poetry & Verse").slug
  end

  test "settings update the name and export heading but keep the slug" do
    notebook = notebooks(:novels)

    get edit_notebook_path(notebook)
    assert_select "input[type=hidden][name='notebook[slug]'][value=novels]"
    assert_select "input[type=text][name='notebook[slug]']", count: 0

    patch notebook_path(notebook), params: { notebook: { name: "Victorian novels", slug: "novels", export_heading: "Reading notes" } }

    assert_redirected_to notebooks_path
    notebook.reload
    assert_equal "Victorian novels", notebook.name
    assert_equal "Reading notes", notebook.export_heading
    assert_equal "novels", notebook.slug

    patch notebook_path(notebook), params: { notebook: { name: "Novels", slug: "renamed" } }
    assert_equal "novels", notebook.reload.slug
  end

  test "another reader's notebook settings cannot be reached" do
    other_notebook = notebooks(:other_research)

    assert_raises(ActiveRecord::RecordNotFound) { get edit_notebook_path(other_notebook) }
    assert_raises(ActiveRecord::RecordNotFound) do
      patch notebook_path(other_notebook), params: { notebook: { name: "Taken" } }
    end

    assert_equal "Private research", other_notebook.reload.name
  end

  test "rejects a blank name" do
    assert_no_difference -> { Notebook.count } do
      post notebooks_path, params: { notebook: { name: "" } }
    end

    assert_response :unprocessable_entity
    assert_select ".errors li", "Name can't be blank"
  end
end
