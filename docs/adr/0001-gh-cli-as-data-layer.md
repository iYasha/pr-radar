# Use the `gh` CLI as the data layer, not in-app GitHub auth

The app talks to GitHub by shelling out to the already-installed, already-authenticated `gh` CLI (`gh api graphql`, search `type: ISSUE`), rather than implementing its own OAuth/PAT flow + URLSession networking. This eliminates all token storage, keychain handling, and auth UI: the app inherits whatever account `gh` is logged into, with access to every org that account already belongs to. GraphQL was chosen over REST because one call returns the full rich row (reviewDecision, statusCheckRollup, additions/deletions, labels, author) at 1 point of a 5000/hr budget, versus REST search's 30/min plus per-PR follow-up calls.

## Considered Options

- **`gh` CLI (chosen)** — zero auth code, reuses existing login, robust raw-query passing via `-f q=`.
- **In-app OAuth / PAT + URLSession** — no external dependency, App-Store-eligible, but requires building auth UI, secure token storage, and refresh handling.

## Consequences

- The app **cannot be sandboxed** (App Sandbox blocks subprocess exec) → not distributable via the Mac App Store. Acceptable: this is a personal tool.
- **Requires `gh` to be installed and authenticated.** App must detect both and guide the user to `gh auth login` when missing.
- GUI apps don't inherit the shell `PATH`, so the app must **locate the `gh` binary itself** (search `/opt/homebrew/bin`, `/usr/local/bin`, etc.).
- Pass the user's query as an opaque GraphQL variable (`-f q=...`); never as a `gh search prs` positional arg, which re-tokenizes queries containing spaces and breaks them.
- A Saved Query's tokens are joined by spaces into that `q` variable; the composed string is exactly what GitHub evaluates. See ADR-0002 (token model) and ADR-0003 (one search call per tab).
