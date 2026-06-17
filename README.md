# PR Radar

macOS menu-bar GitHub PR tracker. Saved queries as tabs; each tab = one GitHub
GraphQL search. See `CONTEXT.md` for the domain language and `docs/adr/` for the
locked decisions.

## Run

**Dev mode** (fast iteration):

```sh
swift build
swift run PRRadar      # or: .build/debug/PRRadar
```

**App bundle** (double-clickable, shareable):

```sh
Scripts/build-app.sh   # → dist/PRRadar.app (release, ad-hoc signed)
open dist/PRRadar.app
```

The bundle is dockless (`LSUIElement`), bundles the fonts
(`ATSApplicationFontsPath`) and `Sparkle.framework`, carries the PR-glyph icon,
and is ad-hoc signed — so it runs on another Mac, but the first launch there
needs a right-click → Open (or `xattr -dr com.apple.quarantine PRRadar.app`)
until it carries a Developer ID. See `Scripts/build-app.sh` for config (bundle
id, version, min macOS, Sparkle feed/key).

Either way it launches as an accessory app (no dock icon) and installs a
menu-bar item (git-pull-request mark). Click it to open the 400×560 panel.
**Settings** (header gear) holds the refresh-interval picker, Check for Updates,
and Quit.

## Releasing & auto-update

Updates ship via [Sparkle](https://sparkle-project.org). Installed copies poll
an appcast and self-update (no Developer ID — verification is by EdDSA signature;
only the very first download needs the right-click → Open).

```sh
Scripts/release.sh 0.2.0      # build → zip → EdDSA-sign → gh release → appcast → push
```

That builds `dist/PRRadar.app` at the given version, zips it, signs the zip with
the Sparkle EdDSA key (private key in the login keychain), publishes a GitHub
release with the zip asset, then regenerates and pushes `appcast.xml` to `main`.
The app's `SUFeedURL` points at the raw `appcast.xml`; `SUPublicEDKey` in the
Info.plist verifies downloads. The icon is regenerated with `Scripts/make-icon.sh`
when `AppIcon.swift` changes.

Distribute by sending people the release zip (or the GitHub release link); after
that, Sparkle handles updates.

Requires `gh` installed and authenticated (`gh auth login`). The app discovers
the binary in `/opt/homebrew/bin`, `/usr/local/bin`, etc. (GUI apps don't inherit
the shell `PATH`). If `gh` is missing or logged out, the panel shows inline guidance.

## Data layer

Each tab shells out to `gh api graphql` (`search(type: ISSUE)`), passing the
composed query as an opaque `-f q=` variable — never a positional arg (ADR-0001).
`is:pr` is injected into every query. One search call per tab (ADR-0003). The
query model is `{ id, name, tokens: [String], countInBadge }`; the search string
is `tokens.joined(" ")` (ADR-0002).

State (queries, active tab, theme) persists to
`~/Library/Application Support/PR Radar/state.json`.

## Layout

```
Sources/PRRadar/
  PRRadarApp.swift      @main App, MenuBarExtra(.window), AppDelegate
                        (accessory policy, font registration, login item)
  Model/
    SavedQuery.swift    { id, name, tokens, countInBadge }; 2 defaults
    PullRequest.swift   row model + status/CI/diff/age derivations
    GitHubClient.swift  gh discovery + Process exec + GraphQL decode
    AppStore.swift      @Observable @MainActor: queries, results cache, refresh
    Persistence.swift   Codable JSON in Application Support
  Design/
    Theme.swift         color tokens (dark/light) + fonts + palette hash
    FeatherIcon.swift    Feather icons hand-drawn as SwiftUI Shapes
    PRMark.swift        git-pull-request NSImage template (menu-bar icon)
    Snapshot.swift      offscreen-render scroll bypass (see below)
    AppIcon.swift       app-bundle icon (PR glyph squircle); rendered via PRRADAR_ICON
  Views/
    PanelView, HeaderView, TabBarView, PRRowView,
    QueryEditorView, SettingsView, AvatarView, FlowLayout
  Resources/Fonts/      Hanken Grotesk, Fragment Mono, Instrument Serif (bundled)
```

Refresh: at launch + when the panel opens + a background timer + the header
refresh button. The timer interval is user-configurable (1/5/15/30 min, default
5) in **Settings** (header gear) and persists in `state.json`. Menu-bar badge =
sum of `issueCount` over queries with `countInBadge` on. Settings also holds the
**Quit** button.

## Verifying the UI without the menu bar

`ImageRenderer` can't open the popover, and it renders `ScrollView` content
empty, so a gated harness swaps scroll views for plain stacks and loads sample
data:

```sh
PRRADAR_SHOT=1 .build/debug/PRRadar      # writes /tmp/panel_{list,light,editor}.png then exits
```

This path is behind the `PRRADAR_SHOT` env var and never runs in normal use.

## Not yet (v2)

- **Notifications** — new-since-last-poll diff, silent baseline, re-entry.

Done: the `.app` bundle (`LSUIElement` + `ATSApplicationFontsPath` + embedded
`Sparkle.framework`, ad-hoc signed, PR-glyph icon) — see **Run**; the
`SMAppService` login item, which registers and sticks once launched from the
bundle; in-panel **Settings** (gear) with a configurable refresh interval and
**Quit**; and **Sparkle auto-update** with a one-command release flow — see
**Releasing & auto-update**.

Not doing: a right-click context menu on the menu-bar item — `MenuBarExtra(.window)`
gives no right-click hook, and a full `NSStatusItem` refactor wasn't worth the
churn. Quit/Settings live in the panel (gear button).
