# Queries are free-typed GitHub qualifier tokens, not an abstract rule builder

The user authors a Saved Query by typing GitHub search qualifiers directly into a tokenizing input. On comma or Enter, each typed fragment crystallizes into a removable chip (a Token, e.g. `is:open`, `review-requested:@me`, `-label:wip`). There is no abstract rule engine and no fixed-vocabulary-only builder — the qualifier text the user types *is* the rule. The v5 add-filter menu (grouped State / Review / People / Labels / Repos / Checks / Meta) survives as an optional shortcut that appends a common token, but the primary path is free typing. Tokens compose (join by space) into one GitHub search string sent to GraphQL `search`; every predicate maps 1:1 to a GitHub qualifier, so the app stores qualifier strings, not a predicate AST.

This refines the earlier "raw query strings only / no builder" decision: the model reconciles raw authoring (you type the filters yourself) with the v5 chip UX (typed text → chips), rather than choosing one or the other.

## Considered Options

- **Free-typed tokens → chips on comma/Enter (chosen)** — raw authoring with a chip affordance; unlimited expressive ceiling; optional menu for convenience.
- **Add-filter-menu-only builder (v5 prototype as literally drawn)** — capped at preset chips, and still needs free-text entry for label/repo values anyway.
- **Single raw-text field, no chips** — simplest model, but discards the chip UX the design specifies.

## Consequences

- Storage is trivial: per query `{ id, name, tokens: [String], countInBadge }`; the search string = `tokens.join(" ")`.
- For chip styling, split each token at the first `:` into key + value (design renders the key in `--fg3`, the value in `--fg`).
- The user must know GitHub search syntax. Acceptable: the user is technical and explicitly chose to type filters.
- Editing affordances: comma/Enter commits a chip; ✕ or backspace-on-empty removes the last chip; click a chip to re-edit its text.
- New GitHub search qualifiers work the day GitHub ships them, with no app change.
