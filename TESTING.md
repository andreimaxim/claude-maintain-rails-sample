# Testing

## Test the contract at its boundary

Use Rails' Minitest integration with real application objects and the test
PostgreSQL database. Exercise the route, controller, model, and rendering stack
for HTTP behavior. When needed, substitute a controlled response at an external
boundary. Do not stub the domain behavior under test.

Choose the smallest boundary that can catch the likely mistake:

| Contract | Test |
| --- | --- |
| A domain decision, transition, or query | `ActiveSupport::TestCase` in `test/models/` |
| Routing, permissions, persistence, HTML, Turbo, or JSON | `ActionDispatch::IntegrationTest` in `test/controllers/` |
| A workflow across endpoints | An integration test in `test/integration/` |
| Browser execution, focus, navigation, or JavaScript interaction | `ApplicationSystemTestCase` in `test/system/` |
| Scheduling, delivery, and job-specific failure behavior | Rails job and mailer test helpers, usually in the request test that queues the job |

Do not add a separate test for every method. Prefer assertions that would survive
an internal refactor. A useful regression test fails for a plausible wrong
implementation, not just a syntax error.

## Commands and current configuration

Use only a disposable test database. Rails may create, reload, or replace its
data. Never point test configuration at development data you need to keep, a
shared environment, or production.

Run commands from the repository root with the pinned Ruby active:

```sh
bundle check
bin/rails zeitwerk:check
bin/rails test
bin/rails test:system
```

`bin/rails test` does not include system tests. The generated
[system test base](test/application_system_test_case.rb) uses Selenium with Chrome,
not headless Chrome. Until that configuration changes, system tests require a
display and a suitable browser and driver.

For focused feedback, run a test directory:

```sh
bin/rails test test/controllers
bin/rails test test/models
```

To run one file, pass its path to `bin/rails test`. Append `:LINE` to that path to
select a test.

The Gemfile keeps Minitest on 5.x because Rails 7.0's test runner fails under
Minitest 6. No RuboCop, security-audit command, or `bin/ci` is configured.

[test/test_helper.rb](test/test_helper.rb) loads all fixtures and configures
processor-count parallel workers.

The [test environment](config/environments/test.rb) disables caching and raises
application exceptions. For error-response or cache tests, set the required mode
explicitly and restore it afterward. Do not assume production behavior. The mail
delivery method is `:test`.

## Make scenarios distinguish the right behavior

- Name the domain fact or user outcome: a rejected edit leaves the body unchanged,
  not merely that an update action runs.
- Keep arrangement, action, and assertions recognizable. Share setup only for
  facts every test in that group needs. Do not hide the decisive input in a helper.
- Establish meaningful preconditions when the operation could otherwise be a
  no-op. Reload records when checking what was persisted.
- Use asymmetric values and contrasting records. A permission test needs another
  user's record. A filter needs both an included and an excluded candidate.
- Derive expected results independently. Do not call the production scope or
  serializer to compute the value the same scope or serializer should return.
- Assert order only where ordering is promised. For membership, include/exclude
  assertions can express the rule better than an exact count of unrelated fixtures.
  Assert total counts when pagination, duplicates, or filtering totals are contractual.
- Test both a successful result and the relevant failure or boundary. A denial
  should check that no unauthorized write or side effect occurred.

Fizzy's [closure tests](docs/references/fizzy.md#card-closure) combine an initially
open card, a state change, and recorded actor/event information. Its
[comment request tests](docs/references/fizzy.md#comments) check that someone
cannot edit another person's comment and that the stored body remains unchanged.
Those are behavioral contracts, not expectations about private method calls.

## Fixtures and time

Use named, coherent fixtures for shared test data. Change or build a record inside
a test when the variation belongs to that scenario alone. See the
[fixture guide](docs/guides/fixtures.md) before adding shared data.

For time-sensitive behavior, freeze or travel to an explicit instant using Rails'
test helpers and exercise the boundary from both sides. Do not make a test depend
on the current wall clock, execution order, or an arbitrary first fixture.

Keep expected text, dates, IDs, and permission outcomes visible where they explain
the test. Helpers should remove setup mechanics, not choose expected results.

## Requests and representations

Use real verbs, route helpers, and request formats. Check status and the important
response contract as well as persistence: redirect destination, `Location`, field
values, absent versus null fields, or the relevant rendered controls.

For HTML, use `assert_select` for semantic elements, labels, error messages, and
form targets. For JSON, assert the intended public representation rather than the
whole Active Record attribute hash. For Turbo streams, check the action, target,
and meaningful content. A stream response does not prove the browser applied it.

For a browser interaction, drive the visible UI and wait on an observable result
instead of sleeping. Include the failure or non-default state the change affects.
Inspect the rendered result at representative widths when appearance changes.

The [view guide](docs/guides/views.md) distinguishes ordinary forms, enhanced
submissions, and interactions that genuinely require browser coverage.

## Queries and caches

An N+1 regression needs several parent records with different associated records.
Measure the query work inside the request or operation, not fixture loading.
Use the database and supported instrumentation; do not assert private ORM calls
or assume helpers from another repository exist here.

For cache tests, enable caching and use a test-local store. Restore the store and
settings in `ensure` or teardown. Exercise a miss, a hit, a relevant data change,
and a contrasting viewer when output varies by permission. A repeat request with
caching disabled proves nothing about a cache.

Fizzy's [board tests](docs/references/fizzy.md#boards-and-caching) request the same
settings as privileged and unprivileged users with partial caching enabled. The
assertion concerns the disabled control, not merely the number of cache calls.
Fizzy's helper uses renderer internals and is not a drop-in helper for this Rails
version.

## External effects and asynchronous work

Use Rails' job and mailer test helpers for enqueuing/delivery contracts. A test of
enqueueing does not establish successful job execution. Exercise domain behavior
separately, and execute the job when its context, serialization, or retries matter.

Native Sidekiq jobs such as `ExportJob` do not use the Active Job adapter.
[test/test_helper.rb](test/test_helper.rb) loads Sidekiq's fake testing mode, which
keeps each pushed job in memory after a JSON round trip, as Redis would. Assert
`ExportJob.jobs` for the enqueued arguments, call `ExportJob.drain` to run them,
and clear them in setup.

The Active Job test adapter serializes arguments, but does not round-trip them
through JSON as Sidekiq does: a `BigDecimal` argument stays a `BigDecimal` in
tests and arrives as a string in a worker. A time with zone is deserialized in
UTC in both.

Digest requests reserve the reader in a real Redis set, so those tests need Redis
(`REDIS_URL`, by default `redis://localhost:6379`). Set `REDIS_URL` to a disposable
Redis database separate from development, for example
`REDIS_URL=redis://localhost:6379/1 bin/rails test`. Reservations are outside the
database transaction, so each test releases the readers and dates it uses before
starting, and uses dates no other test uses. A refused enqueue is substituted at
the queue boundary with Minitest's `stub`.

Keep remote services out of ordinary tests. The citation enrichment tests serve
scripted responses from a loopback HTTP server in the test process, so Faraday's
retry and authentication run for real without an external service. One test boots
a fresh Rails process to verify environment credentials before configuration is
cached. Use a local fake or an already available substitution facility at the
client boundary. Do not introduce a mocking library just to avoid constructing a
model, and do not record real tokens or personal data in fixtures or HTTP recordings.

## Report evidence accurately

Report the command, result, and scope. Separate tests that passed from tests not
run, environment failures, skipped cases, and manual browser checks. A source
example or an inspected test is not a test result for Margin Notes.
