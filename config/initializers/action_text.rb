# Rich text may contain collapsible excerpts. Extend Action Text's inherited
# allowlist, which keeps the safe defaults and attachment markup.
ActionText::ContentHelper.allowed_tags += %w[ details summary ]
