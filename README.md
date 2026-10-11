# Margin Notes

A full-stack Rails reading-notebook application. Readers sign in, keep private
notebooks, and write rich-text notes with small attachments, tags, a highlight
color, and a draft/ready status. The note list at `/notes` (also bookmarked as
`/journal`) supports title search and notebook and status filters. Each notebook
has settings for its name and export heading, and a slug fixed at creation. The app uses Ruby 3.3.6, Rails 7.0.8.7, PostgreSQL, and Rails'
generated importmap/Turbo/Stimulus frontend.

`bin/rails db:seed` creates two development readers, `reader@example.com` and
`other@example.com`, each with the password `password`. There is no registration
or password recovery.

## Develop the application

- [Contributing](CONTRIBUTING.md): environment setup, development, and delivery.
- [Architecture](ARCHITECTURE.md): responsibilities and design conventions.
- [Testing](TESTING.md): behavioral tests, fixtures, browser checks, and commands.
- [Agent instructions](CLAUDE.md): task-specific Rails skills and detailed guides.

The guides use attributed [public Fizzy examples](docs/references/fizzy.md), adapted
to this repository's framework and scope. They are development guidance, not a
request to reproduce Fizzy's features or infrastructure.
