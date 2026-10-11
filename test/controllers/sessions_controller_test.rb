require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "signed-out readers are sent to sign in" do
    get notes_path

    assert_redirected_to new_session_path
  end

  test "signing in with the correct password opens the note list" do
    post session_path, params: { email: " Reader@Example.com ", password: "password" }

    assert_redirected_to notes_path
    follow_redirect!
    assert_select "h1", "Notes"
  end

  test "a wrong password re-renders the form without signing in" do
    post session_path, params: { email: users(:reader).email, password: "wrong" }

    assert_response :unprocessable_entity
    assert_select "[role=alert]", "Email or password is incorrect."
    assert_select "input[name=email][value=?]", users(:reader).email

    get notes_path
    assert_redirected_to new_session_path
  end

  test "signing out ends the session" do
    sign_in_as users(:reader)

    delete session_path
    assert_redirected_to new_session_path

    get notes_path
    assert_redirected_to new_session_path
  end
end
