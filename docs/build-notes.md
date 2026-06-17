# Build notes — production deltas from PR Radar v5

The v5 HTML is the visual + interaction spec. These are the points where production must extend or deviate from it. Architectural decisions live in `docs/adr/`; this file is the smaller stuff.

## Data
- **Always inject `is:pr`** into every composed query. v5 tokens omit it; GraphQL `search(type: ISSUE)` returns issues too, so without it non-PR issues leak in.
- `@me` is resolved server-side by GitHub — pass it through verbatim, don't substitute the login.
- Each tab = one GraphQL `search` call (ADR-0003). Tokens join by space into the `q` variable (ADR-0001, ADR-0002).

## Rendering
- **Avatars:** real `author.avatarUrl` when loaded; fall back to the v5 initials-on-color circle while loading or if missing.
- **Identity/repo colors:** v5 hardcodes a repo→color and author→color map for its sample. Production must **hash** the repo full-name / login deterministically into the accent palette (sage, pink, clay, blue, cyan, periwinkle) — the fixed map won't generalize.
- **Fonts:** bundle Hanken Grotesk (UI sans), Fragment Mono (mono), Instrument Serif (display) in the `.app`; they are not system fonts.
- **Menu-bar icon:** git-pull-request mark (`PRMark.prImage`) as an NSImage template (OS tints it for dark/light status bar) + the count badge overlay.

## Behavior (carried from grilling, additive to v5)
- **Refresh:** on panel-open + 5-min timer + manual. v5 dropped the interval setting; reinstate as a simple default.
- **Badge:** per-Saved-Query `countInBadge` toggle; menu-bar badge = sum of enabled queries. Subtitle shows "N to review · M yours".
- **Theme:** manual dark/light toggle, persisted; default dark.
- **Notifications:** deferred to v2 (semantics: new-since-last-poll, silent baseline, re-entry).

## Shipped default Saved Queries (editable, reorderable, deletable)
Two only. "+" adds a fresh tab — no preset gallery.
1. **To review** — `is:open is:pr review-requested:@me draft:false`
2. **My PRs** — `is:open is:pr author:@me sort:updated-desc`
