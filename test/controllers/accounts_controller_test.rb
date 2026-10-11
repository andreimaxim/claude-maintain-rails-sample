require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:reader) }

  test "a reader chooses their time zone" do
    get edit_account_path
    assert_select "select[name=?] option[selected]", "user[time_zone]", "(GMT+00:00) UTC"

    patch account_path, params: { user: { time_zone: "Tokyo" } }
    assert_redirected_to edit_account_path
    assert_equal "Tokyo", users(:reader).reload.time_zone

    patch account_path, params: { user: { time_zone: "Mars/Olympus Mons" } }
    assert_response :unprocessable_entity
    assert_select ".errors", /Time zone is not included in the list/
    assert_equal "Tokyo", users(:reader).reload.time_zone
    assert_equal "UTC", users(:other_reader).reload.time_zone
  end
end
