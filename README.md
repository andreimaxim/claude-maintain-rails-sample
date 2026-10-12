# Margin Notes

A full-stack Rails reading-notebook application. Readers sign in, keep private
notebooks, and write rich-text notes with small attachments, tags, a highlight
color, and a draft/ready status. The note list at `/notes` (also bookmarked as
`/journal`) supports title search and notebook and status filters. Each notebook
has settings for its name and export heading, and a slug fixed at creation. The app uses Ruby 3.3.6, Rails 7.0.8.7, PostgreSQL, and Rails'
generated importmap/Turbo/Stimulus frontend.

A reader can import notes into a notebook from a UTF-8 CSV file of up to 100
notes and 100 KB, with this header row:

```csv
title,body_html,doi,annotation,reminder_epoch
```

Only `title` is required. `body_html` becomes the rich-text body. A `doi` looks
like `10.1234/example`. `annotation` is the reader's plain-text comment on the
citation, and `reminder_epoch` is a time in seconds since 1970 (UTC). An imported
reminder is scheduled from its note. The import shows a preview with each row's
source line and errors before anything is saved, then imports all rows or none.

A DOI can also be entered on the note form. From a note's page, a reader can fetch
the cited work's title and source URL from a citation metadata provider. The page
shows whether that request is pending, completed, or failed. Citations, and so
their metadata, are shared by every reader who cites the same DOI. Requests run in
a Sidekiq worker; development uses a local stand-in provider (see
[Contributing](CONTRIBUTING.md#prepare-the-environment)).

A reader can export a notebook as a Markdown file. The export runs in the
Sidekiq worker; its page shows whether it is queued, working, complete, or
cancelled, how many notes it has processed, and its job ID. A queued or working
export can be cancelled. A completed file can be downloaded for 24 hours.

A reader can schedule an email reminder for a note at a date and time in their
time zone, chosen on the account settings page, and postpone it by a day. From
the notes page, a reader can request an email digest of the ready notes updated
that day, once per UTC day. The digest's day and the request limit both use the
UTC date of the request, which can differ from the reader's date near midnight.
Email is written to files in
development rather than sent (see [Contributing](CONTRIBUTING.md#prepare-the-environment)).

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
