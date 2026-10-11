# Readers choose a page size through the per_page URL parameter, capped at 50.
require "pagy/extras/items"
# A page past the end, such as a stale bookmark, shows the last page instead of failing.
require "pagy/extras/overflow"

Pagy::DEFAULT[:items] = 10
Pagy::DEFAULT[:items_param] = :per_page
Pagy::DEFAULT[:max_items] = 50
Pagy::DEFAULT[:overflow] = :last_page
