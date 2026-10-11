---
name: writing-rails-controllers
description: Develops Rails routes, controllers, request concerns, and HTTP behavior in Margin Notes. Applies to endpoint changes, parameters, authorization boundaries, response formats, and request tests.
---

# Writing Rails controllers

Build controllers whose responses and persisted results can be verified through
real requests. Keep domain decisions out of HTTP handling.

Read the [architecture](../../../ARCHITECTURE.md),
[controller guide](../../../docs/guides/controllers.md), and
[testing conventions](../../../TESTING.md). The guide's
[public sources](../../../docs/references/fizzy.md) are examples, not dependencies.

- Trace the route, lookup scope, domain call, response, and nearest request test
  before choosing the change. Use the application's authentication if present.
  Do not add authentication as part of an unrelated controller edit.
- Name the resource and its HTTP contract. Choose permitted inputs and ownership
  separately. Accepting an ID does not authorize access to that record.
- Put reusable domain rules in the model and shared request mechanics in small,
  purposeful controller concerns. Use the model skill when those rules change.
- Define success and the relevant invalid, missing, or forbidden case. Preserve
  submitted values for correctable form errors and avoid writes on rejected requests.
- Use the view skill when HTML, Turbo streams, or JSON representations change.
  Check the actual caller's format, not only the easiest request to test.
- Verify focused request tests, then the applicable broader tests. Report results
  and missing coverage using the testing guide. Never substitute mocked model
  calls for the behavior the endpoint is supposed to expose.
