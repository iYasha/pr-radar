# Evaluate each query server-side — one GraphQL search per tab

Each Saved Query runs as its own server-side GitHub GraphQL `search(type: ISSUE)` call: the tab's count comes from `issueCount`, its rows from the returned nodes. The app does **not** fetch a PR universe and filter it client-side. The PR Radar v5 prototype's client-side `match()` evaluator works only because its data is a fixed in-memory sample (`rawPRs()`); production scope is "all repos the `gh` login can reach," which has no bounded universe to fetch-then-filter.

## Considered Options

- **Server-side per query (chosen)** — correct for unbounded scope; each tab is an independent search; query semantics are exactly GitHub's, so no qualifier needs custom code.
- **Fetch-once superset + client-side filter (prototype model)** — instant tab switching and an instant live "Matches N" while editing, but it silently breaks for any tab querying outside the fetched superset (a different author, a repo not in the set) and is impossible when the scope is every accessible repo.

## Consequences

- N tabs = N GraphQL calls per refresh. Each costs ~1 point of the 5000/hr GraphQL budget — negligible.
- The editor's "Matches N right now" line is a **debounced** GraphQL search fired as the user edits tokens, not a local computation.
- The prototype's `match()` JS is discarded for production, kept only as a semantics reference (e.g. `involves:@me` = author is me OR review requested from me).
- Cache the last results per query and refresh on panel-open + interval, so tab switching shows cached rows immediately rather than a spinner.
