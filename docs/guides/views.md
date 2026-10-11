# Views, forms, and browser behavior

Margin Notes uses server-rendered HTML with ERB, Turbo, and Stimulus. Jbuilder is
available for JSON when a feature calls for it. Read
[ARCHITECTURE.md](../../ARCHITECTURE.md) and [TESTING.md](../../TESTING.md) alongside
this guide. The [public sources](../references/fizzy.md) supply concrete examples.
These conventions also cover states the examples do not demonstrate.

## Separate representation from domain decisions

The controller selects the records and response format. The model exposes domain
facts and operations. Templates and helpers turn those facts into HTML or JSON.
They should not query for unrelated records, authorize a write, or change data.

Use action templates to compose a page and partials for named reusable pieces.
Give a partial explicit inputs for its resource and any actor-dependent rendering.
Do not require it to know which controller set an instance variable. Helpers may
format or compose presentation, but should not hide a second data-loading layer.

Before changing a shared partial, inspect all callers and the values each supplies.
A resource used on a full page may also appear in a frame, stream, mailer, or JSON
representation with a different context.

## Start with meaningful HTML

- Use links for navigation and buttons/forms for mutations. Do not hide a write
  behind a GET link or a JavaScript click handler with no form semantics.
- Give inputs persistent labels, errors that identify the affected field, and
  appropriate input types. A placeholder is not a label.
- Give icon-only controls accessible names. Preserve keyboard access and visible
  focus. Choose where focus should go after inserting, removing, or replacing content.
- Design empty, validation-error, read-only, and permission-dependent states as
  carefully as the populated happy path. Disabled controls do not enforce server
  permissions.
- Escape user-provided text by default. Use the framework's rich-text and
  sanitization facilities only where the feature supports rich content. Do not
  mark arbitrary user input as safe HTML.

Fizzy's [board settings](../references/fizzy.md#boards-and-caching) compose a form
from partials. This simplified, newly written example makes the resource,
permission input, and label explicit:

```erb
<%= form_with model: board do |form| %>
  <%= form.label :name, "Board name" %>
  <%= form.text_field :name, required: true, readonly: !editable %>
  <%= form.submit "Save changes", disabled: !editable %>
<% end %>
```

The caller supplies `board` and `editable`. The receiving controller still checks
permission. This example assumes the board resource from Fizzy. Margin Notes has
no board route or model.

## Forms need both success and failure behavior

Use `form_with` and the current object so field names, values, routing, and CSRF
tokens follow Rails conventions. On a correctable validation failure, rerender
the object containing the submitted values and errors with an error status.
Do not reconstruct a blank object and make the user re-enter the form.

For ordinary forms, keep a useful HTML submission path and layer enhancement on
it. If a feature intentionally requires JavaScript, say so and test that contract.
Do not claim a no-JavaScript fallback merely because the markup contains a form.

Fizzy's comment submission uses a specialized editor and a submit button enabled
by JavaScript. Its mutation actions negotiate Turbo or JSON, not ordinary HTML.
That is a useful interaction example, not evidence that its comment flow works
with JavaScript disabled. Its editor is not part of this application's dependencies.

## Choose a page, frame, or stream

A full-page visit, a frame navigation, and a stream update solve different needs:

- A frame isolates a navigable region. Its response must supply the expected frame,
  and links that leave the region need an intentional target.
- A stream describes a specific DOM operation. Use stable, unique IDs derived from
  the record and its role when several representations appear on one page.
- A successful form response may redirect, replace a region, or update several
  regions. Choose the smallest update that preserves the user's current work.

Fizzy's [comment streams](../references/fizzy.md#comments) insert the new comment
before the form, reset the form region, and remove the matching container on
deletion. Its [closure streams](../references/fizzy.md#card-closure) update both
the card and the affected board regions. Identify every page region the operation
affects, not just the easiest controller response to return.

Use ordinary stream operations supported by the local dependency versions. Do
not depend on another application's refresh/morph behavior or custom Turbo fork
without checking compatibility and the intended interaction.

Consider empty-to-populated and populated-to-empty transitions, validation
failures, duplicate IDs, a focused editor, and back navigation. An HTTP `200` with
a stream body can still update the wrong region or discard an unsaved draft.

## Keep Stimulus local to the interaction

Use targets, values, and actions to connect behavior to its rendered element.
Respect native submission and constraint validation instead of building a second
submission protocol. Clean up listeners, timers, or subscriptions introduced by
the controller so reconnecting does not duplicate effects.

Fizzy's [form controller](../references/fizzy.md#browser-interaction) uses
`requestSubmit()`. Its draft controller clears local storage only after a
successful Turbo submission. Preserve entered text when a request fails.
If storing drafts is requested here, also decide how keys separate users and
resources, and how logout or shared-device use affects privacy.

Do not add client state that merely mirrors a server-owned permission or status.
Keep JavaScript within the importmap/Stimulus setup unless a concrete requirement
justifies a different asset toolchain.

## JSON is an explicit public representation

Use Jbuilder templates and reusable resource partials when an endpoint needs JSON.
Choose fields, nesting, timestamps, and URLs deliberately. Do not expose every
model attribute through automatic serialization, or let a private field appear
because a new column was added.

The action template defines the envelope or collection. A resource partial defines
a consistent resource representation. Pass its resource and other dependencies
explicitly. Separate representations when audiences have materially different
contracts rather than hiding many permission branches in one partial.

Fizzy's [comment JSON partial](../references/fizzy.md#comments) distinguishes rich
body HTML from plain text and composes its creator representation. It uses route
helpers for canonical URLs. Use this example to guide representation design.
Do not assume Fizzy's body schema or field names define Margin Notes' API.

Test omitted versus null fields and empty collections when those distinctions
matter. Assert output values through requests rather than how Jbuilder was called.

## Cache only after naming every dependency

Keep the initial uncached representation correct. Before introducing a fragment
or JSON cache, identify everything that changes the result: record versions,
associated data, permissions, locale, and URL context where relevant.

Use cache keys and invalidation rules that account for those inputs, split the
viewer-specific portion out, or leave it uncached. Including a record alone does
not automatically account for every association or helper it reads. Never rely
on a hidden client-side control to make cached private content safe.

Fizzy's [board cache test](../references/fizzy.md#boards-and-caching) warms the
settings view as a privileged user and then checks the disabled state for another
user. Its board-name callback demonstrates a separate related-record dependency.
Use the [testing guide](../../TESTING.md#queries-and-caches) for cold/warm and
invalidation checks. Do not copy Fizzy's renderer-internal instrumentation blindly.

## Verify what people see and do

Use request tests for semantic HTML, form destinations, error messages, JSON, and
stream targets/content. Use browser tests for submission, focus, frame navigation,
and Stimulus behavior. Inspect visual changes in the affected states and widths.
Code review alone does not establish usable layout.

Keep assertions about meaningful output rather than incidental wrapper nesting,
CSS utility ordering, or private helper calls. When a visual check or browser test
cannot run, state that limitation rather than calling the UI verified.
