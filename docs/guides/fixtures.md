# Fixtures

Use fixtures for a small, understandable dataset shared by tests. This guide
covers records under `test/fixtures`. Read [TESTING.md](../../TESTING.md) for
scenario design.

## Build relationships people can follow

Use labels that identify the record's role in a scenario. Connect associations by
label rather than repeating generated numeric IDs. Keep each child's parent and
actor consistent with the scenario.

Fizzy's [fixture examples](../references/fizzy.md#fixtures-and-test-support)
connect a board to named cards, comments to cards, and a closure to the closed
card. Readers can trace those labels from fixtures to domain and request tests.

This reduced adaptation shows ordinary Rails associations without Fizzy's custom
ID scheme. It assumes matching `writebook` and `editor` fixtures and the source
associations. It is not a complete dataset or a request to add those models here.

```yaml
# cards.yml — illustration, not a local fixture
shipping:
  board: writebook
  title: Ship the release

# closures.yml — a separate fixture file in an application with these models
shipped:
  card: shipping
  user: editor
```

Use Rails' normal association labels with the local schema. Do not copy
another application's fixture-ID overrides or tenant layout.

## Keep the baseline small

Add a shared fixture when several tests need the same domain distinction.
Prefer changing a record inside an isolated test for a one-off boundary condition.
Do not duplicate an entire fixture graph just to vary one field.

Keep a useful included/excluded pair for filters and permissions. Do not add
unrelated records solely to force all tests to assert a whole-database count.
Conversely, do not remove contrasting records just to make a broad query pass.

Fixture contents should be ordinary domain data, not a catalogue of testing edge
cases. Use synthetic names, text, addresses, and file contents. Never import real
user data, credentials, or production exports as convenient examples.

## Make time and order deliberate

Use fixed, mutually consistent dates for the shared baseline. Arrange a fixed
clock and the needed dates inside tests of deadlines or recency. A relative ERB
timestamp in a shared fixture can change test preconditions as time passes.

Do not infer ordering from fixture declaration order or primary keys. Set the
attributes that drive the domain ordering and include a tie only when testing
the tie-breaker. When an ordering is contractual, assert identities in order.

Fizzy's fixtures contain relative dates and a custom UUID mechanism. Those are
source-specific details, not patterns this guide asks Margin Notes to reproduce.

## Rich content and files

Keep Action Text and Active Storage fixture relationships explicit. Note bodies
live in `test/fixtures/action_text/rich_texts.yml`, linked through the
polymorphic record (`record: middlemarch (Note)`). Fizzy uses the same
arrangement. See the
[public rich-text fixtures](../references/fizzy.md#fixtures-and-test-support).
Serialized columns take their stored form in fixtures. For example, note `tags`
is a JSON string, and notebooks need an explicit `slug` because fixtures skip
callbacks.

Use small file fixtures that represent the format under test. A realistic upload
test should check the content or metadata that matters, not merely that any path
was accepted. Do not install a rich-text editor or storage backend only to match
an example.

## Change shared data carefully

Search for callers of a fixture label before changing its meaning. Run affected
model, request, and browser tests as applicable. A fixture edit can change a
permission, query result, or cache dependency far from the edited file.

Keep seeds and test fixtures separate unless a feature explicitly establishes a
shared loading mechanism. [db/seeds.rb](../../db/seeds.rb) creates two development
readers with one notebook each. The fixtures define their own `reader` and
`other_reader` with the password `password`, plus contrasting notebooks and notes.
