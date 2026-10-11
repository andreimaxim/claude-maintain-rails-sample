# Models and domain behavior

Use with [ARCHITECTURE.md](../../ARCHITECTURE.md) and
[TESTING.md](../../TESTING.md). The [public examples](../references/fizzy.md)
illustrate responsibility boundaries, not a proposed schema for Margin Notes.

## Put decisions beside the facts they use

Keep persistence, domain predicates, and state transitions together when they
describe one concept. A controller or job should ask for an operation by name
rather than coordinate several model internals itself.

Fizzy's `Card::Closeable` groups a closure association, open/closed scopes, state
predicates, actor/time accessors, and the transitions. Its `close` operation clears
postponement, creates the closure, and records an event inside a transaction.
Its controller does not repeat those writes. See the
[closure sources](../references/fizzy.md#card-closure).

A concern should group a cohesive capability, not serve as a file for each method.
Keep small behavior on the model until an extracted module has a clear name and
responsibility. Model-specific capabilities can live in that model's namespace.
Use the shared concerns directory only for actual reuse.

## Choose the object you need

- Use Active Record for a concept whose persisted identity and relationships are
  part of the behavior.
- Use a plain Ruby object for a computation or operation that does not need a row.
- Use Active Model when a nonpersisted object needs validations or form conventions.
- Introduce an external client for a real network boundary, not a generic repository
  wrapper around Active Record.

Name objects for their domain responsibility. Avoid catch-all managers
and services that accumulate operations unrelated to the records they coordinate.

## Keep the public API intention-revealing

Favor methods that describe the domain action, with explicit inputs for an actor
or option that changes its meaning. Keep helper methods private. A predicate
should answer a question rather than cause an unrelated write or network request.

Define each transition's result and failure behavior. Consider invalid starting
states, repetition, and competing operations. Fizzy's `close` and `reopen` guard
their current state, but a Ruby guard by itself does not establish safety under
concurrent writes. Choose constraints or locking for the local invariant instead
of claiming concurrency guarantees from that example.

Use bang names consistently with the surrounding API. They distinguish a stronger
variant, not simply any destructive method. Preserve framework conventions such
as `save` versus `save!` rather than renaming framework behavior.

## Queries should compose

Return relations from scopes intended for further filtering or pagination. Name
them by the domain meaning, and keep filtering separate from ordering when callers
need to combine them differently. Use parameterized query APIs for user input.

This shortened, Rails 7-compatible excerpt from the public closure concern shows
queries based on the authoritative association rather than a second stored flag:

```ruby
scope :closed, -> { joins(:closure) }
scope :open, -> { where.missing(:closure) }
```

The excerpt assumes the source model's `has_one :closure` association. It is not
standalone code to paste into an unrelated model. Decide whether joins can create
duplicate parents, whether ordering is stable, and which associated records the
representation will read.

Do not make every relation preload every association. The request's representation
usually determines the needed loading. Put a reusable preload scope on the model
only when it represents a recurring requirement.

## Enforce invariants at the right boundary

Model validations provide meaningful failures to application callers. Database
constraints protect facts that must hold across concurrent operations and alternate
write paths. A uniqueness validation is not a substitute for a unique index.

Use a transaction for a group of writes that must succeed together. Keep remote
effects outside assumptions about database rollback. When a callback enqueues work
or emits a notification, account for commit timing and duplicate delivery.

Keep callbacks local and predictable. They can maintain a record's derived
properties or trigger its documented lifecycle behavior. Prefer an explicit
domain method for coordinating a user workflow.

Fizzy's [comment model](../references/fizzy.md#comments) rejects comments on a
non-commentable card even when called without its controller. Its
[board capability](../references/fizzy.md#boards-and-caching) touches associated
cards after a name change, with a test contrasting another update. Those examples
show why callback conditions and cross-record invalidation deserve direct tests.

## Readable Ruby and model layout

Keep related declarations together: included capabilities, associations,
validations/callbacks, named queries, then behavior. Prefer a consistent local
ordering over introducing a formatter's rulebook that the repository does not use.

Put class-level behavior before instance methods, public APIs before private
helpers, and helpers near the flow that calls them. Use ordinary conditionals
where both outcomes matter. A guard clause is useful when it eliminates an
exceptional case and leaves the main path easier to read. Do not rewrite unrelated
working code just to enforce a stylistic preference.

The public [Fizzy style guide](../references/fizzy.md#style-and-version) provides
examples of domain-oriented controllers, method ordering, and small jobs. These
guides adopt the responsibility ideas without requiring all of its formatting choices.

## Test the model through its public behavior

Exercise decisions with real records and the database. Assert persisted state,
returned results, and contractual effects, rather than private calls or a list
of Active Record declarations.

Cover the case that would distinguish a plausible wrong predicate or transition:
an excluded record, an already-completed operation, another actor, or a failed
write within a multi-write operation. Reload when persistence matters. Avoid tests
whose only claim is that Rails implements an ordinary association macro.

Keep scenario-specific data in the test and shared facts in
[fixtures](fixtures.md).
