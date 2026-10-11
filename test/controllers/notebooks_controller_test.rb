require "test_helper"

class NotebooksControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:reader) }

  test "lists only the reader's notebooks" do
    get notebooks_path

    assert_select "li", text: "Novels"
    assert_select "li", text: "Private research", count: 0
  end

  test "creates a notebook owned by the reader" do
    assert_difference -> { users(:reader).notebooks.count } do
      post notebooks_path, params: { notebook: { name: "Poetry" } }
    end

    assert_redirected_to notebooks_path
  end

  test "rejects a blank name" do
    assert_no_difference -> { Notebook.count } do
      post notebooks_path, params: { notebook: { name: "" } }
    end

    assert_response :unprocessable_entity
    assert_select ".errors li", "Name can't be blank"
  end
end
