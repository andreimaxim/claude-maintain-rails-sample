# Controllers and request boundaries

Use with [ARCHITECTURE.md](../../ARCHITECTURE.md) and
[TESTING.md](../../TESTING.md). Examples refer to public Fizzy code recorded in
the [source notes](../references/fizzy.md). Cards and boards are not local models.

## Choose a resource and a response contract

Start with the caller: which resource is addressed, what changes, who may do it,
and what should be returned? Use Rails' standard REST actions rather than adding
a controller method for every domain verb. HTML resources can have `new` and
`edit`; JSON-only resources need not expose those form actions.

Fizzy models closing and reopening a card as creation and deletion of a closure.
This reduced routing example illustrates that boundary. It is not an instruction
to create the resource in Margin Notes:

```ruby
resources :cards do
  scope module: :cards do
    resource :closure, only: [:create, :destroy]
  end
end
```

The [closure controller](../references/fizzy.md#card-closure) delegates to `close`
and `reopen`. The resource names the HTTP operation, and the model decides what the
transition means. Do not invent a persistence table solely because an endpoint
has a resource name.

## Separate permitted input from permission

Resolve records through the caller's authorized scope once authentication exists.
Resolve a child through that parent, rather than performing an unrestricted
global lookup followed by a comparison. Authentication, ownership, and permission
to perform a particular action are distinct checks.

Fizzy's [comment controller](../references/fizzy.md#comments) first obtains an
accessible card, then finds the comment through the card, and checks who can edit
it. Its domain validation also prevents comments on a draft card. This example
does not supply an authentication implementation for the sample.

Keep a narrow parameter method. This Rails 7-compatible example permits only the
comment body:

```ruby
def comment_params
  params.require(:comment).permit(:body)
end
```

This is an adaptation, not Fizzy's current implementation. Set trusted ownership
and actor fields from the authenticated context or parent association, not from
submitted parameters. Choose nested attributes deliberately. Do not permit all
fields because one form currently sends only a few.

## Keep actions readable

An action should make its lookup, domain operation, and response easy to find.
Simple creation can use an association's `build` or `create!`. Put complex rules
in a domain method. Use small private methods to name request mechanics without
hiding the action in a chain of callbacks.

Use `before_action` for shared setup whose scope is apparent. Restrict it to the
actions that need it. Extract a controller concern when several controllers share
a coherent request capability, not to relocate arbitrary private methods.

Models own domain rules, as described in the [model guide](models.md). Controllers
should not duplicate those eligibility checks or write domain data just to
simplify a view.

## Make each format deliberate

| Result | Typical response |
| --- | --- |
| HTML read | Render its page or the requested frame |
| Successful HTML mutation | Redirect to a useful GET, ordinarily with `:see_other` for an enhanced form |
| Correctable form validation error | Render the form with its submitted object, errors, and `:unprocessable_entity` |
| Turbo stream mutation | Return the targeted updates the current page needs |
| JSON creation | `:created`, the canonical representation, and a meaningful `Location` |
| JSON update | Canonical representation, or `:no_content` if no body is promised |
| JSON deletion | `:no_content` once the deletion succeeds |

These are choices to make for the endpoint, not formats every action must support.
An HTML redirect, a frame response, and a stream response are different contracts.
Do not infer that a Turbo-only action has a working no-JavaScript fallback.

Use `save`/`update` and a rendered error state for ordinary user-correctable form
validation. Use bang methods where failure should interrupt an operation, with
an intentional error boundary. Do not rescue every exception into a successful
response or expose raw exceptions to callers.

Keep permission failures, missing resources, and invalid input distinguishable
according to the endpoint's disclosure policy. Test the chosen response and
absence of writes. Keep CSRF protection for browser mutations, and never mutate
state through GET.

## Queries follow the representation

Start from the authorized relation. Apply filters and ordering before pagination.
Use a deterministic secondary order when ties affect page membership.
Preload the associations the [view](views.md) actually reads. Avoid turning a
relation into an array early just to filter or sort in Ruby.

Fizzy's [board controller](../references/fizzy.md#boards-and-caching) composes
card scopes and preloading before rendering a page. Do not copy its pagination
helper or assume its adapter behavior. Those dependencies are not installed here.
Margin Notes paginates with Pagy 8.6.3. `NotesController#index` calls `pagy` on
its finished relation; [its initializer](../../config/initializers/pagy.rb) sets
the page-size parameter and limits.

For expensive list endpoints, test contrasting records and several associated
objects. Assert membership and the declared ordering or count contract. A broader
association count is useful only when it explains that contract. Follow the
testing guide for cache and query measurements.

## Verify through requests

Use `ActionDispatch::IntegrationTest` and actual routes. For a mutation, check the
response and the reloaded state. A denied mutation needs an unchanged-state
assertion. For a representation, check meaningful field values or HTML controls,
not just a successful status or the name of a rendered template.

Fizzy's closure tests combine a persisted transition with stream or JSON response
assertions. Comment tests include a different author's record. These tests verify
behavior that mock expectations on `close` or `update` would miss.

Read the [Rails 7 controller guide](https://guides.rubyonrails.org/v7.0/action_controller_overview.html)
for parameter, callback, rendering, and CSRF APIs. Use documentation matching the
local locked framework rather than copying a newer reference application's syntax.
