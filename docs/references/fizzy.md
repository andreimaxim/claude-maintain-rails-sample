# Public examples and source notes

These development guides use public
[basecamp/fizzy](https://github.com/basecamp/fizzy) as a source of concrete Rails
design examples. References are pinned to
[ea3cc44be97878babf86d4f453c53ee509d9393a](https://github.com/basecamp/fizzy/commit/ea3cc44be97878babf86d4f453c53ee509d9393a)
so readers can inspect the same code rather than a moving default branch.

The prose is written for Margin Notes. Code illustrations are labeled as excerpts
or adaptations. These references are source evidence, not results from running
Fizzy or its tests. Keep the accompanying [Fizzy license notice](fizzy-license.md)
with Fizzy-derived examples.

## Style and version

- [STYLE.md](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/STYLE.md): readable methods, REST resources, domain-oriented models, and shallow jobs.
- [AGENTS.md](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/AGENTS.md): an example of concise repository-specific context rather than a framework manual.
- [Gemfile](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/Gemfile) and [Gemfile.lock](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/Gemfile.lock): this reference uses Rails 8.2 alpha and a custom Turbo branch.

Margin Notes starts on Rails 7.0.8.7 with PostgreSQL and the generated asset stack.
The controller illustration therefore uses `require(...).permit(...)`, not the
newer parameter API used upstream. Do not import Fizzy's database adapters,
custom fixture identifiers, tenancy, editor, deployment, or cache/job backends as
implicit dependencies. General Rails 7 APIs are documented in the
[controller](https://guides.rubyonrails.org/v7.0/action_controller_overview.html) and
[testing](https://guides.rubyonrails.org/v7.0/testing.html) guides.

## Card closure

- [Routes](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/config/routes.rb): closure as a nested singular resource.
- [Card::Closeable](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/models/card/closeable.rb): association-backed state, query scopes, and transactional transitions.
- [Closures controller](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/controllers/cards/closures_controller.rb) and [CardScoped](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/controllers/concerns/card_scoped.rb): authorized lookup and HTTP delegation.
- [Closure controls](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/views/cards/container/_closure_buttons.html.erb) and [create stream](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/views/cards/closures/create.turbo_stream.erb): a mutation form and updates to affected page regions.
- [Model tests](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/test/models/card/closeable_test.rb) and [request tests](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/test/controllers/cards/closures_controller_test.rb): transitions, actor, event, stream, and JSON results.

The routing example includes only the two actions discussed. The model example
includes only two scopes. Neither is a complete feature or a concurrency guarantee.

## Comments

- [Comment model](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/models/comment.rb) and [Card::Commentable](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/models/card/commentable.rb): validation at the domain boundary and a parent-owned relationship.
- [Comments controller](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/controllers/cards/comments_controller.rb): nested lookup, creatorship checks, and response negotiation.
- [New-comment form](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/views/cards/comments/_new.html.erb) and [HTML partial](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/views/cards/comments/_comment.html.erb): rich input, stable DOM identities, and reusable presentation.
- [Create stream](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/views/cards/comments/create.turbo_stream.erb) and [destroy stream](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/views/cards/comments/destroy.turbo_stream.erb): insert/reset and removal targets.
- [JSON partial](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/views/cards/comments/_comment.json.jbuilder): explicit fields, rich and plain body forms, and composed creator data.
- [Model tests](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/test/models/comment_test.rb) and [request tests](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/test/controllers/cards/comments_controller_test.rb): invalid domain state, forbidden edits, persistence, and JSON contracts.

The parameter illustration intentionally permits only the body. The source also
supports other inputs. This example is not a default permit list for a new application.
The source comment form is JavaScript-dependent, not a demonstrated HTML fallback.

## Boards and caching

- [Boards controller](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/controllers/boards_controller.rb): conventional HTML forms, scoped lookup, query composition, and conditional responses.
- [Settings page](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/views/boards/edit.html.erb) and [name partial](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/views/boards/edit/_name.html.erb): form composition; the guide's illustration adds an explicit permission input and visible label.
- [Board JSON partial](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/views/boards/_board.json.jbuilder): conditional public fields.
- [Board::Cards](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/models/board/cards.rb) and [its test](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/test/models/board/cards_test.rb): related-record touching specifically when the name changes.
- [Request tests](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/test/controllers/boards_controller_test.rb) and [caching helper](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/test/test_helpers/caching_test_helper.rb): a warm-cache permission check and restored test settings.

The sample guides require explicit partial inputs and analysis of cache dependencies.
They do not endorse every use of implicit request context or caching in the source.

## Browser interaction

- [Form controller](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/javascript/controllers/form_controller.js): native submission and validation.
- [Local-save controller](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/app/javascript/controllers/local_save_controller.js): draft persistence and clearing only on successful submission.
- [Browser smoke tests](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/test/system/smoke_test.rb): visible card/comment/attachment workflows.

Fizzy has no `writing-rails-views` skill at this revision. The local skill is newly
written from these examples for a full-stack Rails application. Accessibility,
error-state, and no-JavaScript guidance are local requirements, not claims that
every upstream flow satisfies them.

## Fixtures and test support

- [Boards](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/test/fixtures/boards.yml), [cards](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/test/fixtures/cards.yml), and [closures](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/test/fixtures/closures.yml): named relationship examples.
- [Comments](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/test/fixtures/comments.yml) and [rich-text bodies](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/test/fixtures/action_text/rich_texts.yml): separate content fixtures tied to their record.
- [Test helper](https://github.com/basecamp/fizzy/blob/ea3cc44be97878babf86d4f453c53ee509d9393a/test/test_helper.rb): shared test context, application-specific fixtures, and dependency integrations.

The fixture illustration omits the source's account fields, custom UUID handling,
and relative dates. Its labels and text are simplified. It demonstrates ordinary
association labels only, not a portable copy of the original dataset.
