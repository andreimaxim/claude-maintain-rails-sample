# Developing Margin Notes

## Prepare the environment

Use the Ruby version in [.ruby-version](.ruby-version) and Bundler version in
[Gemfile.lock](Gemfile.lock). PostgreSQL must be available, with a local role that
can create the development and disposable test databases configured in
[config/database.yml](config/database.yml).

For an Amp orb, [.agents/setup](.agents/setup) installs the toolchain, database
services, and gems, then prepares the databases.
[.agents/resume](.agents/resume) starts the database services after activation.
These scripts change the environment and databases. Do not run them on a
production machine.

When using mise without shell activation, prefix a command with `mise exec --`,
for example `mise exec -- bin/rails test`. The repository's
[mise configuration](mise.toml) enables the Ruby version file.

With the toolchain and PostgreSQL installed, run:

```sh
bundle install
bin/rails db:prepare
bin/rails server
```

Citation metadata requests and notebook exports are background jobs. To complete
them in development, also run a Sidekiq worker and, for citations, the local
stand-in provider, each in its own terminal:

```sh
bundle exec sidekiq
bin/citation-provider
```

The worker needs Redis. The provider listens on `127.0.0.1:9393` and accepts the
development credentials in [config/secrets.yml](config/secrets.yml). Its header
comment lists the DOI endings that simulate a missing record or an unavailable
provider. To use another provider, set `CITATION_PROVIDER_URL`,
`CITATION_PROVIDER_USER`, and `CITATION_PROVIDER_PASSWORD` for both the server and
the worker.

Development caching is off by default, so the exports page renders its
availability indicator without a cache. Run `bin/rails dev:cache` to toggle Rails'
development cache and exercise the cached indicator.

Do not commit decrypted credentials, the master key, local connection secrets,
or recordings containing personal information. Supply real credentials through
the environment or the application's credential mechanism only when needed.

## Implement one observable behavior

Read the relevant [task skill](CLAUDE.md#task-skills) and its guide. Start with the
existing route, model, representation, and test closest to the requested change.
For a new feature, build a small working path through these layers before adding
abstractions for hypothetical variants.

Decide what a caller should observe, including the important rejection or empty
case. For a bug, reproduce the wrong result before changing its implementation
when practical. Keep refactoring separate from a deliberate contract change.

Run focused tests while working, then the broader commands in [TESTING.md](TESTING.md).
For UI changes, inspect the affected states in a browser. A passing request test
cannot establish that a layout or interaction works. Report which checks ran,
including failures, skipped checks, and empty suites.

## Review and delivery

- Inspect the complete diff, including generated files and dependency changes.
- Preserve unrelated local work. Do not reset a database or discard a file to
  make a check pass without understanding what it contains.
- Keep commits coherent. Explain behavior and non-obvious choices rather than
  listing edited files. This repository has no ticket-prefix convention.
- Commit, push, or open a pull request only within the user's requested delivery
  scope. A successful local check does not mean a change has been published.
- When commands, ownership, or conventions change, update their existing guide
  rather than adding a competing instruction elsewhere.
