# PR Radar

A macOS menu-bar app that surfaces the GitHub pull requests you care about — the ones you authored and the ones you need to review. The whole panel is driven by saved queries shown as tabs; switching a tab re-filters the PR list live.

(The product is "PR Radar"; the repo folder stays `github-pr-bar` — no rename, per workspace rules.)

## Language

**Saved Query**:
A named, ordered list of GitHub search qualifier tokens (e.g. `is:open`, `review-requested:@me`, `draft:false`). The tokens compose into one GitHub search string the app runs (GraphQL `search`); the results render as the active tab's PR list. The app's single core concept — review rules, "my PRs", everything is a Saved Query.
_Avoid_: Rule, watch, filter (as a noun for the whole query)

**Token**:
One GitHub search qualifier inside a Saved Query — a `key:value` fragment (or `-key:value`) the user free-types. On comma or Enter the typed text crystallizes into a removable chip; the composed query is the tokens joined by spaces.
_Avoid_: Filter, term, tag

**Tab**:
The selector for one Saved Query across the top of the panel, with a name and a live count pill. Exactly one tab is active at a time; only the active query's results show. Tabs are drag-reorderable.
_Avoid_: Section, group, page

**Defaults**:
The two Saved Queries shipped on first run — To review and My PRs. Editable, reorderable, and deletable like any other; not special-cased. The "+" button adds a fresh tab (no preset gallery).
_Avoid_: Built-ins, presets (as fixed/locked)

**Author**:
The GitHub user who opened a pull request. `author:@me` is the qualifier behind the default "My PRs" tab.
_Avoid_: Owner, creator
