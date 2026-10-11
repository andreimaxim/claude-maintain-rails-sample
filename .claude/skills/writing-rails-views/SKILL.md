---
name: writing-rails-views
description: Develops Rails ERB views, partials, helpers, forms, Turbo responses, Stimulus interactions, and Jbuilder representations in Margin Notes. Applies to rendered content, accessibility, UI behavior, caching, and representation tests.
---

# Writing Rails views

Render usable HTML or JSON from explicit inputs. Use request or browser checks
according to the behavior under test.

Read the [architecture](../../../ARCHITECTURE.md),
[view guide](../../../docs/guides/views.md), and
[testing conventions](../../../TESTING.md).
[Public examples](../../../docs/references/fizzy.md) cover HTML, Turbo, and JSON.

- Trace the controller, model APIs, template, helpers, and every caller of a shared
  partial before changing its inputs or output. Keep queries and mutations out of
  presentation code.
- Use semantic HTML and the existing asset stack. Add Stimulus for a concrete
  browser behavior, not to duplicate the server's authorization or persistence.
- Decide the supported HTML, frame, stream, and JSON contracts explicitly. Treat
  empty, invalid, pending, and permission-dependent states as part of the feature.
- Pass dependencies to reusable partials and keep private content out of shared
  caches. Follow the guide's cache-key and invalidation rules when caching is useful.
- Assert rendered meaning through requests. Exercise browser-only behavior in a
  real browser and inspect representative visual states for appearance changes.
  A successful template render is not proof that a stream or interaction works.
- Use the controller or model skill when fixing a representation requires changes
  to their contracts. Do not hide the problem in a helper or a second client model.
