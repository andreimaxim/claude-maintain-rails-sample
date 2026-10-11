# Architecture

## Starting point

Margin Notes is a reading-notebook application. Implemented so far:

- A reader (`User`) signs in with email and password through `has_secure_password`.
  `SessionsController` stores only the user ID in the Rails session.
  `ApplicationController#require_sign_in` protects the application's other
  controllers, but not Rails' Active Storage controllers.
- A reader owns `Notebook`s, and each `Note` belongs to one notebook. A note's
  owner is its notebook's owner, so `User#notes` (through notebooks) is the
  authorized note scope. There is no separate `user_id` on notes.
- `NotesController#index` serves `/notes` and its `/journal` alias. It lists the
  reader's notes newest first with an ID tie-breaker, and supports title search
  and notebook and status filters. `show` renders one note's rich body.
- Pagy 8.6.3 paginates that filtered list after ordering, 10 notes per page by
  default. The search form offers 5, 10, 25, or 50 as the `per_page` URL
  parameter. Larger requested sizes are capped at 50. Next and previous links keep
  the filters and page size. A blank, zero, negative, or nonnumeric page shows the
  first page, and a page past the end shows the last page. The form never sends
  an invalid size. A blank, zero, negative, or nonnumeric `per_page` in a URL is
  not handled, and Pagy raises `Pagy::VariableError`.
- A note's body is Action Text (`has_rich_text :body`), edited with Trix.
  Attachments are Active Storage blobs on the local Disk service. `Note` rejects
  saves that embed a blob over 1 MB. Direct uploads store blobs before this
  validation, without a size limit. Rejected or abandoned uploads remain
  unattached, and nothing purges them. No image processor is installed, so images
  use the original blobs, not variants. A migration converted existing plain-text
  bodies to escaped rich text.
- Action Text sanitizes rich text when it renders. The
  [Action Text initializer](config/initializers/action_text.rb) adds
  `details`/`summary` to the default allowlist for collapsible excerpts. Trix
  does not support those elements. Stored excerpts render as collapsible content,
  but saving them through the editor permanently flattens that structure, even
  when only tags or highlight change.
- Note tags are a JSON array in a text column, entered as a comma-separated
  list (`Note#tag_list`). The highlight color is `color` in the `settings` jsonb
  column, which the form edits as `highlight_color`.
- `NotebooksController#edit`/`update` are notebook settings. The slug is derived
  from the name on creation and is read-only afterward (`attr_readonly`). The
  settings form resubmits it unchanged. The export heading is stored in the
  serialized `preferences` hash. Markdown exports use both.
- A reader imports a CSV into one owned notebook. `ImportPreviewsController`
  reads the upload and renders a preview without saving. The preview page sends
  the CSV text back in a hidden field, and `ImportsController#create` reads and
  validates it again rather than trusting the preview. `Import#apply` saves the
  import and each row's note in one transaction. If any row cannot be saved,
  nothing from the batch remains. The receipt page and its CSV download list
  each imported note's title and DOI. Submitting the same preview twice creates
  two imports.
- `Import` accepts one format: UTF-8 CSV with the header row
  `title,body_html,doi,annotation,reminder_epoch`, at most 100 notes and 100 KB.
  Only the title is required. Previews identify rows by their source line, so a
  quoted multi-line body keeps the line where its row starts. Body HTML takes the
  same Action Text assignment and render-time sanitization as the editor.
- A `Citation` is identified by its DOI, the table's `doi` primary key, and is
  shared by every reader who cites it. A DOI is stored as given apart from
  surrounding whitespace, so case variants are different citations. Rows in one
  import share a new citation. Two simultaneous imports that introduce the same
  new DOI can conflict; the losing request fails with a server error and saves
  nothing. A reader's annotation and optional reminder epoch belong to the note,
  not the citation. Annotations are plain text in both the preview and note page;
  line breaks are preserved on the note page, but markup is displayed literally.
  Nothing schedules reminders yet.
- A reader can also enter a DOI on the note form (`Note#doi=`), which cites the
  shared citation with that exact, trimmed DOI or creates it.
- A reader requests metadata for the citation on one of their notes with
  `CitationEnrichmentsController#create`, nested under the note. It resolves the
  note through `current_user.notes`, so another reader's note, or a note without
  a DOI, is a 404. `Citation#request_enrichment` marks the citation pending and
  queues `CitationEnrichmentJob`, unless a request is already pending. The job
  calls `Citation#enrich`, which stores the provider's title and source URL and
  marks the citation completed, or records a failure message. Metadata and
  status belong to the shared citation, so every note citing the DOI shows them.
  The note page shows the state; it does not update itself while pending.
- `Citation::Provider` is the HTTP client for the metadata provider. It reads
  its URL and basic-auth credentials from [config/secrets.yml](config/secrets.yml)
  through `Rails.application.secrets`; that file reads them from the environment.
  Faraday retries a GET once on 503. A 401, 403, or 404, or a response without a
  title and an http(s) URL, fails the enrichment at once. A 429 or 5xx, timeout,
  or connection failure raises `Citation::Provider::Unavailable`. The job retries
  that with `retry_on`, three attempts in all at exponentially longer waits, then
  records the failure instead of passing the error to Sidekiq's own retries. A
  persistently unavailable provider therefore receives at most six requests per
  enrichment request. A job that fails for another reason uses Sidekiq's retries
  and leaves the citation pending meanwhile.
- [bin/citation-provider](bin/citation-provider) is a deterministic local stand-in
  for the provider, used for development and demonstrations. No real provider or
  credentials are configured.
- A reader exports an owned notebook as Markdown from its exports page
  (`ExportsController`, nested under the notebook). `Notebook#request_export`
  saves a queued `Export`, then queues the native Sidekiq job `ExportJob` and
  stores its job ID, which the page shows. The export is committed before the
  job is queued so the worker can always load it. If Redis refuses the job, the
  export is removed and the request fails. Each request creates a new export.
- `Export#generate`, run by the worker, marks the export working with the
  notebook's note count, then writes the notes oldest first (creation time, then
  ID). The file starts with the notebook's export heading, or its name when none
  is set. Each note is a second-level heading with its title on one line,
  followed by its body as Action Text plain text. Markdown characters are not
  escaped. Progress is saved after each note. A retried job starts again from
  the first note. There is no failed state: while Sidekiq retries a failing job,
  the export shows as working and the reader can cancel it.
- Cancelling (`ExportCancellationsController`) sets a queued or working export's
  persisted status to cancelled under its row lock. The worker checks that status
  before each note and before completing, then stops and keeps no file. Completed
  and cancelled exports cannot be cancelled.
- The worker uploads the file to Active Storage (`<slug>.md`) before marking the
  export completed, so a completed export always has a file. It can be downloaded
  for 24 hours (`Export::AVAILABLE_FOR`). `ExportDownloadsController` resolves the
  export through the reader's notebook, so another reader's export is a 404, and
  checks `Export#downloadable?` on every request before any conditional response.
  An expired, cancelled, or unfinished export redirects to the exports page. The
  file is sent by the application, never by an Active Storage URL, with an ETag
  and Last-Modified from the stored file and `private, must-revalidate`.
  A failed upload can leave an unattached blob row without a stored file. Nothing
  cleans up those rows, and each failed retry can leave another one.
- The exports page caches each completed export's availability indicator as a
  fragment that expires at the export's deadline. The download action does not
  read that cache. The page does not update itself while an export is queued or
  working. Nothing purges expired files; they remain in storage.
- Active Storage serves blobs through signed URLs from its own controllers. Those
  URLs are not checked against the signed-in reader. The embedded blob redirect
  URLs do not expire, although the Disk-service URLs they redirect to do.
  The direct-upload controller checks CSRF, not sign-in; the public sign-in page
  supplies a CSRF token to anonymous clients. This sample has no private-file
  access policy or upload-abuse protection for a public deployment.

These conventions guide further features without prescribing a schema in advance.

The initial runtime is Ruby 3.3.6 and Rails 7.0.8.7 with Rails 7.0 defaults.
[Gemfile](Gemfile), [Gemfile.lock](Gemfile.lock), [.ruby-version](.ruby-version), and
[config/application.rb](config/application.rb) are the executable sources of truth.

- PostgreSQL is the application database. Use Active Record and migrations for
  application-owned records, constraints, indexes, and transactions.
- ERB renders HTML. The generated app includes Sprockets, importmap, Turbo, and
  Stimulus. Jbuilder is available for requested JSON representations, but an HTML
  feature does not automatically need a JSON API.
- Rails includes the mailer, job, storage, and cable frameworks. Their presence
  does not mean mail delivery or broadcasts are implemented features. File
  uploads exist only as rich-text attachments.
- Active Job uses Sidekiq 6.5 as its adapter outside tests, so queued jobs are
  kept in Redis (`REDIS_URL`, by default `redis://localhost:6379`) and run in a
  separate `bundle exec sidekiq` process. Tests use Active Job's test adapter.
  `ExportJob` is a native Sidekiq job rather than an Active Job, so its job ID can
  be shown. Sidekiq stores its arguments as JSON, and it uses Sidekiq's default
  retries.
- Action Text 7.0.8.7 bundles Trix 1.3.4. That version cannot load saved HTML
  that has attributes, such as links or attachments, so the layout loads Trix
  1.3.5 from `vendor/javascript` as a classic script. Trix 1.x is not an ES
  module, so it is not in the import map. `@rails/actiontext` is.
  The vendored build comes from the [Trix 1.3.5 release](https://github.com/basecamp/trix/tree/1.3.5)
  and includes its [MIT license](vendor/javascript/trix-1.3.5.LICENSE).
- Orb setup starts PostgreSQL and Redis. Redis holds Sidekiq's queues; it is not
  an application cache. The generated production cable configuration names Redis.
  That configuration is not a verified deployment.

## Prefer Rails objects with clear responsibilities

Use the framework's ordinary directories and interfaces:

| Responsibility | Home |
| --- | --- |
| HTTP verbs, paths, and resource nesting | `config/routes.rb` |
| Parameter selection, authorized lookup, response negotiation | `app/controllers/` |
| Persistent state and domain operations | `app/models/` |
| A cohesive capability of one model | A namespace beneath `app/models/` |
| Behavior genuinely shared across models | `app/models/concerns/` |
| HTML, Turbo stream, and JSON representations | `app/views/` |
| Presentation helpers | `app/helpers/` |
| Browser interaction around rendered HTML | `app/javascript/controllers/` |
| Background execution and retry boundary | `app/jobs/` |
| Mail composition | `app/mailers/` and its views |

A controller can call Active Record directly for a simple save. A multi-step
domain transition belongs behind a meaningful model method, not a sequence of
unrelated updates in the controller. Use a plain Ruby object or Active Model when
an operation needs its own object but no database table. Do not introduce a
mandatory service, repository, presenter, or command layer between every pair of
Rails objects.

Fizzy models closing a card as a singular closure resource. Its controller calls
`Card#close`, and `Card::Closeable` owns the association, predicates, and transaction.
The [closure sources](docs/references/fizzy.md#card-closure) illustrate a resource
boundary and a domain method, not a requirement to add cards to Margin Notes.

## Model resources, not collections of verbs

Use the conventional REST actions, including `new` and `edit` for HTML forms.
When a new operation does not fit an existing resource, look for the resource it
creates, updates, or removes before adding a custom action. Keep nesting shallow
enough that the parent conveys ownership rather than reproducing the whole schema.

Use route helpers in views and responses. Controllers choose the representation.
Models do not construct controller responses or reach into request parameters.

## Keep data ownership and effects explicit

- PostgreSQL owns durable application facts. Derive a value from those facts
  unless storing it solves a demonstrated query, history, or concurrency need.
- Put invariants used outside HTTP in the domain model. Add database constraints
  when integrity must also hold across concurrent requests and non-model writes.
- Keep related database writes in one transaction. Do not assume it can undo a
  remote request, an email, or a job already sent to another system.
- Jobs should delegate to domain behavior and carry the identifiers or context
  they need. Decide retries, duplicate delivery, and transaction timing when a
  real background feature is introduced, rather than adding a queue preemptively.
- Keep network clients at visible boundaries. Preserve failure information and
  distinguish a legitimate empty response from a failed operation.

Fizzy's [comment example](docs/references/fizzy.md#comments) enforces comment
eligibility in both the model and the controller. Callers outside HTTP must obey
the same rule.

## Authorization is not presentation

Define ownership and the authorized lookup scope together. Resolve records
through the signed-in reader: `current_user.notebooks` and `current_user.notes`.
Direct lookups outside that scope raise `ActiveRecord::RecordNotFound`, which is
a 404 in production. A submitted `notebook_id` is resolved through
`current_user.notebooks.find_by`, never assigned directly. A missing or foreign
notebook fails validation and renders the form with 422, without saving the note.
Resolve nested records through their authorized parent. Neither an unguessable ID
nor a hidden or disabled button grants or checks permission.

Keep actor-dependent decisions explicit in domain APIs and reusable rendering.
If request-local state is introduced, set and reset it at the request boundary.
Jobs, mailers, and tests must not rely on a previous request having populated it.
Do not adopt a tenancy or identity scheme solely because a reference application
uses one.

## Render on the server, enhance in the browser

Use HTML forms and links for their native semantics. Turbo handles navigation,
frames, and targeted replacements. Stimulus supplies local interaction that HTML
does not provide. Keep persistence and authorization on the server, not in a
second client-side model of the domain.

Partials take the resources and presentation inputs they need. A template may
compose several resources. A reusable partial should not depend on a particular
controller's incidental instance variables or on undeclared request context.
See the [view guide](docs/guides/views.md) for HTML, accessibility, Turbo, and JSON.

## Optimize the actual representation

Start with correct queries and clear response contracts. Filter and order before
pagination. Use a stable tie-breaker where page membership must be deterministic.
Load the associations that the rendered representation uses rather than adding
a universal preload list to every request.

Define cache keys and invalidation rules before introducing caching. Include
permissions, locale, and related-record changes when they affect the output, or
keep those parts outside the shared fragment. The
[board example](docs/references/fizzy.md#boards-and-caching) illustrates why a
warm cache must be tested with another viewer, not just the same request twice.

## Scope and reference boundaries

The [public examples](docs/references/fizzy.md) are evidence for design ideas, not
a compatible application template. Their Ruby, Rails, database adapters, asset
pipeline, editors, and helper libraries differ from this repository. Use the
locked local APIs, and introduce new infrastructure only for a requested feature.

As features land, document their ownership and invariants here. Keep detailed
layer practices in the [model](docs/guides/models.md),
[controller](docs/guides/controllers.md), and [view](docs/guides/views.md) guides,
and verification rules in [TESTING.md](TESTING.md).
