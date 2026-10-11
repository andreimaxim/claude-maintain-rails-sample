---
name: writing-rails-models
description: Develops Rails models, domain objects, concerns, associations, queries, and persistence rules in Margin Notes. Applies to domain transitions, validations, callbacks, schema-backed behavior, and model tests.
---

# Writing Rails models

Expose domain operations through a clear public API that enforces invariants.
Make it testable with real records, independently of HTTP and presentation.

Read the [architecture](../../../ARCHITECTURE.md),
[model guide](../../../docs/guides/models.md), and
[testing conventions](../../../TESTING.md). Read the
[fixture guide](../../../docs/guides/fixtures.md) when changing shared test data.

- Find the existing owner of the behavior and its callers. Prefer a meaningful
  model method or query over a new layer that merely forwards calls.
- State the invariant, its inputs, and observable result. Include relevant
  repeated calls, conflicting states, actor differences, and failure boundaries.
- Keep concerns cohesive: a capability with its own association, query, and
  behavior is different from splitting a long file into arbitrary fragments.
- Make transactions, database constraints, and remote effects match the actual
  integrity requirement. Do not infer concurrency safety from a sequential test.
- Test public domain behavior and persisted results. Choose cases that distinguish
  the intended rule from a plausible wrong condition.
- Coordinate with the controller or view skill when their contracts change, then
  run the focused and broader tests appropriate to those callers.
