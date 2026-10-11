# Development accounts. Both use the password "password".
return unless Rails.env.development?

reader = User.find_or_create_by!(email: "reader@example.com") { |user| user.password = "password" }
other_reader = User.find_or_create_by!(email: "other@example.com") { |user| user.password = "password" }

reading = reader.notebooks.find_or_create_by!(name: "Reading list")
reading.notes.find_or_create_by!(title: "Notes on Middlemarch") do |note|
  note.body = "Dorothea's idealism and the limits of a provincial town."
end

other_reader.notebooks.find_or_create_by!(name: "Private research")
  .notes.find_or_create_by!(title: "Another reader's private note", status: :ready)
