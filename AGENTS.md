# AGENTS.md — Working in the AppBox repo

Canonical onboarding guide for humans and AI agents contributing to AppBox.

## What AppBox is

A macOS tool for iOS developers to deploy Development / Ad‑Hoc / In‑house (Enterprise) apps over the air via Dropbox: it uploads an `.ipa`, generates an OTA install manifest + short link, and can notify via Slack / Microsoft Teams / email.

There is also a small command‑line tool (`appboxcli`).

## Related repositories (local paths)

Local, non-public context lives in `AGENTS.local.md` (gitignored) — read it too if it is present.

| Repo | Local Path | What |
|------|------------|------|
| https://github.com/getappbox/AppBox-iOSAppsWirelessInstallation | `~/Projects/AppBox-iOSAppsWirelessInstallation` | **Main macOS app** GUI and CLI app (Swift/SwiftUI). |
| https://github.com/getappbox/install-helper | `~/Projects/install-helper` | **The AppBox backend** (Swift/Vapor, Docker). |
| https://github.com/getappbox/WebApp | `~/Projects/WebApp` | **Production** repo for the OTA install web page `web.getappbox.com`. |
| https://github.com/getappbox/fastlane-plugin-appbox | `~/Projects/fastlane-plugin-appbox` | **Fastlane plugin** for AppBox (Ruby). |
| https://github.com/getappbox/AppBox-iOS-SDK | `~/Projects/AppBox-iOS-SDK` | **iOS SDK** for integrating app updates via AppBox (Swift). |
| https://github.com/getappbox/Home | `~/Projects/AppBox-Home` | **Home** repo for the AppBox website `getappbox.com` (static HTML). |

## Architecture
The app is three modules:

```
AppBoxCore  (local Swift Package, UI-FREE)         ← all business logic, models, Core Data
   ├── linked by → AppBox (GUI: Swift/SwiftUI)     ← composition root + UI only
   └── linked by → appboxcli (CLI: standalone)     ← composition root + ArgumentParser + auth
```

The GUI is 100% Swift/SwiftUI, business logic lives in `AppBoxCore`, and `appboxcli` links Core directly.

### Hard rules (do not violate)

1. **No UI in `AppBoxCore`.** No `import AppKit` / `import SwiftUI` in Core — it must link into the CLI. UI is expressed only through protocols (e.g. `ProgressReporter`); the GUI and CLI each provide their own implementation.
2. **Dependency injection by initializer only.** Core types take their collaborators as protocol‑typed init parameters. No hidden singletons (`*.shared`) inside Core types. Each of GUI and CLI builds its own composition root (`AppEnvironment`) from production adapters.
3. **Core Data: v4 only, model is frozen.** Do **not** edit `AppBox.xcdatamodeld` (no entity or attribute renames — even the `dbDirectroy` typo stays). Swift `NSManagedObject` subclasses must keep explicit ObjC names matching the v4 model exactly: `@objc(ABProject)`, `@objc(ABUploadRecord)`, `@objc(ABProvisioningProfile)`, `@objc(ABProvisionedDevice)`, and `@objc(AppBoxService)` (**not** prefixed). Getting one wrong crashes on store load. Read a build's app folder through `ABUploadRecord.linkSettings`, never raw `dbFolderName`: GUI and v3 records keep only the first segment of a nested folder, CLI records can hold `//`, and that folder is what a delete removes when an app's last version goes.
4. **Shared store + shared Keychain.** GUI and CLI open the same Core Data SQLite store (fixed Application Support path, pinned by `ABStorePaths` to the v3 location so upgrades don't orphan data) and share the Dropbox token through a common Keychain service string. Both are signed with team `3PQ7E4L589`.
5. **Every change ends shippable + green.** Never leave `develop` with a broken build or red tests at a session boundary. Small, self‑contained commits.
6. **Swift-native & Apple-first dependencies.** Prefer Swift SDKs over Objective-C ones (Dropbox → **SwiftyDropbox**, not `ObjectiveDropboxOfficial`) and a built-in Apple framework over a third-party dep wherever one exists (`os.Logger` not CocoaLumberjack; URLSession; CryptoKit). Keep a third-party dep only where Apple has no equivalent (ZIP → a **Swift** ZIP package, not the ObjC SSZipArchive).
7. **All cloud storage goes through `StorageProvider`.** Dropbox is just the first `DropboxStorageProvider`; the upload pipeline and UI depend on the protocol, never on a provider SDK. **No SwiftyDropbox (or any provider) type may leak outside its provider file.** Adding a backend (Google Drive, S3, …) must be a new file + a registry entry — nothing else.
8. **`appboxcli` is heading for full independence.** The CLI must keep working on a machine where the GUI has never run: CI runners are its main consumer, and each project wants different settings. So anything the GUI can configure has to be settable on the command line too; `AppPreferences` (the app's `com.developerinsider.AppBox` defaults domain) is a *fallback* for parity with the GUI, never the only source. Install-page settings resolve as **flag → app preference → built-in default** (more details on, IPA link off, previous versions on, 100 MB chunks); `DefaultSettings` writes those same values on the app's first launch, and `AppPreferences.FirstRun` must stay in step with it. A preference the GUI never wrote falls back to that default — never to a Swift zero value, which is how CLI uploads silently lost "more build details". Do not add a CLI behaviour that can only be driven from the GUI's preferences. The same holds for upload history: the GUI pre-fills "Keep the same link" and its folder from the app's latest upload in the shared store, but the CLI never does. A CI run must not change behaviour because of what was uploaded from that machine before, so `--keepsamelink` / `--dbfolder` stay explicit on every run.
9. **No change stops at its own repo.** AppBox is six repos, and the five that ship code share one set of wire formats — every one of them can be broken from outside. Before you finish a change to the macOS app, `AppBoxCore`, `appboxcli`, `install-helper`, the iOS SDK or the fastlane plugin, **work out which of the others consume what you touched, grep those checkouts to confirm, and say what you found** — in the PR body or your summary, even when the answer is "nothing else consumes this". They are all cloned locally (paths in the table above), so there is no excuse for guessing. Editing `install-helper` means checking the GUI, CLI, SDK, fastlane plugin and WebApp; editing the CLI means checking the fastlane plugin (it shells out to `appboxcli`) and the GUI (shared store); editing the upload pipeline means checking the SDK and WebApp (they both read `appinfo.json`). A change that lands green here and silently breaks a consumer is a broken change. If a consumer needs a matching change, either make it in the same pass or write it into `plans/follow-ups.md` before you stop — never leave it undiscovered.
10. **Keep the living docs current.** Whenever you make meaningful progress or the user gives a new instruction, update `AGENTS.md` and `plans/follow-ups.md` in the same change. The docs are the contract; stale docs are a bug.

### Cross-repo contracts (what rule 9 is protecting)

Everything below is a format or interface with a producer in one repo and a consumer in another. Changing one without its consumers is the failure mode rule 9 exists to catch.

| Contract | Produced by | Consumed by | Breaks if changed |
|---|---|---|---|
| `appinfo.json` — `latestVersion`, `versions[]`, `uniqueLinkShared`, `uniqueLinkShort`, and the per-build fields | `AppBoxCore` (`AppInfoJSON`, `AppInfoFile`; rewritten by `DeleteCoordinator`) | **iOS SDK** (`AppInfo.swift`), **WebApp** install page | The SDK stops finding updates; the install page renders blank fields. Both decode tolerantly, so a rename fails silently rather than loudly. |
| Install link — `https://web.getappbox.com?url=` + the Dropbox share path, with `%`, `&` and `#` escaped | `AppBoxCore` (`InstallLink.make`) | **WebApp**, **iOS SDK** (`AppBoxLink`), **install-helper** path validation | Testers get a dead install page, and the SDK cannot resolve the link it was given. |
| `install.getappbox.com` — `/appinfo/s/**`, `/appinfo/scl/**`, `/install/**`, `/cors`. Unauthenticated, per-IP 300/min, forces `dl=1`, path must start `/s/` or `/scl/` | **install-helper** | **WebApp**, **iOS SDK** | Every installed build that watches a link stops updating — including builds already on devices, which cannot be fixed by shipping new code. |
| `api.getappbox.com/api/v1/*` — `X-AppBox-Client-Token` plus the caller's Dropbox bearer token | **install-helper** | GUI + CLI via `AppBoxServiceClient` (short links, mail, webhooks, config, latest-version) | Uploads still work but lose short links, email and notifications. |
| `~/.appbox_share_value.json` — `APPBOX_SHARE_URL`, `APPBOX_IPA_URL`, `APPBOX_MANIFEST_URL` | `appboxcli` (`ShareURLExport`) | **fastlane plugin** (`appbox` action), SDK example's `Scripts/upload.sh` | Lanes report success but export no `APPBOX_*` values, so downstream steps get empty links. |
| `appboxcli upload` flags — `--ipa`, `--emails`, `--message`, `--keepsamelink`, `--dbfolder`, `--slackwebhook`, `--msteamswebhook` — and its exit codes (**111 = build is live but the email failed**, not a failure) | `appboxcli` | **fastlane plugin**, SDK example's `Scripts/upload.sh` | Renaming a flag breaks every CI lane in the wild. Treat retired options the way `--webhookmessage` is treated: accepted and ignored, never removed. |
| Shared Core Data store (pinned by `ABStorePaths`) + shared Keychain service string | GUI and CLI equally | GUI and CLI | One side orphans the other's data or Dropbox session. |
| `releases/latest/download/AppBox.dmg` — the fixed asset name the download page links straight at (no GitHub API, so no rate limit) | this repo's releases (`Scripts/build-release.sh`) | **Home** (`getappbox.com/download`), `install.sh` (`AppBox.app.zip`) | A release published without the asset 404s for every visitor. |
| Keep-same-link folder layout — one `appinfo.json` per bundle identifier, replaced in place | `AppBoxCore` upload pipeline | **iOS SDK** (its entire premise: an installed build watches one link forever) | Every future upload becomes invisible to builds already installed. |

## Module / source layout

| Path | What |
|------|------|
| `AppBox/` | The GUI app — **100% Swift + SwiftUI; zero Objective‑C** (no `.m`/`.h`/`.pch`). `@main struct AppBoxApp: App` + `@NSApplicationDelegateAdaptor(AppDelegate)`; Home/Dashboard are `Window` scenes hosting Swift NSViewControllers via `NSViewControllerRepresentable`; the menu is `.commands`. SwiftUI screens are NSViewController-hosted islands (`NSHostingView`); shared styling lives in `IslandStyle.swift` (`IslandMetrics`, `IslandTypography`, `.islandTypography()`). Key dirs: `Common/`, `Model/`, `ViewController/`. No storyboard, no pch, no generated `AppBox-Swift.h` (`SWIFT_INSTALL_OBJC_HEADER = NO`). Reach the AppDelegate via `AppDelegate.appDelegate` (captured in init — `NSApp.delegate` is SwiftUI's wrapper, see [[appbox-appdelegate-adaptor-cast]]). The GUI consumes Core's **native async API** directly (`UploadCoordinator.run`/`DeleteCoordinator.run`/`IPAExtractor`) — the `@objc(AB…)` upload/delete/extract bridges are gone. |
| `AppBoxCore/Sources/AppBoxCore/CoreData/Resources/AppBox.xcdatamodeld/` | Core Data model (loaded via `CoreDataStack` from `Bundle.module`). Current = `AppBox4` (frozen). |
| `AppBoxCLI/` | The CLI (Swift, `swift-argument-parser`). Links Core directly and runs the upload itself through `BuildPublishService` — it does **not** drive the GUI. Install-page settings come from flags, falling back to `AppPreferences` (see hard rule 8). |
| `AppBoxCore/` | The shared Swift package. `Backend/` holds `AppBoxServiceClient` + `DropboxAppKeyProvider` (the install-helper API client). |
| `AppBoxTests/` | XCTest target (pure Swift). |
| `.github/workflows/` | `xcodebuild.yml` (build + test, on `master` and `develop`), `gh-pages.yml` (docs). |
| `docs/` | mkdocs site (published to GitHub Pages — keep planning docs OUT of here). |

## Dependencies

Current: Swift Package Manager only (ZIPFoundation, swift-argument-parser, **SwiftyDropbox** — in `AppBoxCore`, wrapped by `DropboxStorageProvider` / `DropboxSession` / `DropboxTransport`). `ObjectiveDropboxOfficial`, SSZipArchive, CocoaLumberjack, and the vendored `ABPrivate` framework have all been removed. No CocoaPods / Carthage, no vendored binaries.

**How each concern was resolved (rules 6–7):**
| Concern | From | To |
|---------|------|----|
| Dropbox SDK | `ObjectiveDropboxOfficial` (ObjC xcframework) | **SwiftyDropbox** (SPM), behind `DropboxStorageProvider` |
| Logging | CocoaLumberjack | `os.Logger` (Apple unified logging) |
| ZIP/unzip | SSZipArchive (ObjC) | a **Swift** ZIP package (e.g. ZIPFoundation), behind `ArchiveExtractor` |
| Networking | URLSession (already) | URLSession behind `HTTPClient` |
| Hashing/crypto (if any) | — | CryptoKit |
| Cloud storage | Dropbox only | provider-agnostic `StorageProvider` + registry (Google Drive / S3 / … are future drop-ins) |

## Build, test, run

```bash
# Build the GUI
xcodebuild build -project AppBox.xcodeproj -scheme AppBox \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Run the test plan (this is what CI runs). NOTE: the test plan is wired to the
# AppBoxTests scheme, not the AppBox scheme.
xcodebuild test -project AppBox.xcodeproj -scheme AppBoxTests -testPlan AppBoxTests \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# AppBoxCore package alone. IMPORTANT: use `xcrun swift`, not bare `swift`.
# On this machine `swift` on PATH is a swiftly-managed 6.1.3 that is INCOMPATIBLE with the
# Xcode 26 SDK (fails with: could not build module '_Builtin_float'). `xcrun swift` resolves
# to Xcode's default toolchain, which is what the app build uses. (CI has no swiftly, so plain
# `swift test` is fine there.)
cd AppBoxCore && xcrun swift test
```

Outside `AppBoxCore`, write `AppBoxCore.ProgressReporter`: the macOS 27 SDK adds `Foundation.ProgressReporter`, so the bare name is ambiguous in any file that imports both, and the build fails.

Never start a modal from Home's `viewWillAppear` / `viewDidAppear`. SwiftUI orders the Home window front inside AppKit's launch open-event, before `applicationDidFinishLaunching`, and AppKit aborts any `runModal()` started there: it returns `.abort` instantly and nothing is shown. That is how the CLI update prompt silently never appeared in 4.0–4.1. Launch-time prompts belong in `AppDelegate`, dispatched to the main queue after launch and skipped when `isHostingTests` is true, so the AppBoxTests host never blocks on a modal.

Coverage is enabled in `AppBoxTests/AppBoxTests.xctestplan` (scoped to the `AppBox` target). CI prints `xccov` report; gating is by diff coverage on changed Swift (ratchets up by phase).

### Release builds (Developer ID)

`Scripts/build-release.sh` builds, signs and packages both shippable products into `dist/` (gitignored):

```bash
Scripts/build-release.sh                # both products, Developer ID signed
Scripts/build-release.sh -tb            # test, then build
Scripts/build-release.sh -t -s core     # only the AppBoxCore package tests, nothing built
Scripts/build-release.sh -bc            # build only the standalone CLI
Scripts/build-release.sh -tbnk AppBox   # test, build, notarize + staple (DMG is default)
```

The flags are composable actions — `-t/--test`, `-b/--build`, `-n/--notarize` (implies `-b`) — combined with targets `-g/--gui` and `-c/--cli` (neither means both). Short flags cluster (`-tb`), only the last flag of a cluster may take a value (`-tbndk AppBox`), and every long option also accepts `--name=value`. With no action flag the script builds; `-t` on its own tests and exits.

Everything shippable lands in one versioned directory:

```
dist/AppBox-<version>/
  AppBox.dmg          drag-to-Applications image — what getappbox.com/download serves
  AppBox.app.zip      the same AppBox.app, zipped with ditto — what install.sh downloads
  appboxcli.zip       appboxcli/ — binary + AppBoxCore_AppBoxCore.bundle + install.sh
```

**Every release must include `AppBox.dmg`.** The download page links straight at `releases/latest/download/AppBox.dmg` (no GitHub API, so no rate limit), so a release published without one 404s for every visitor. The DMG is therefore built by default with the GUI; `--no-dmg` skips it for fast local iteration only.

The `.tar.gz` artifacts are gone — nothing consumed them once `install.sh` moved to the zip, which is the format `ditto` produces and consumes.

Build intermediates (`AppBox.xcarchive`, `gui-export/`, `cli-derived/`, `cli-stage/`, `logs/`) stay directly under `dist/`, so the release directory holds only distributable files. Both products are signed with `Developer ID Application` (team `3PQ7E4L589`), hardened runtime, secure timestamp. Notarization needs a stored `notarytool` profile (`xcrun notarytool store-credentials`) or `APPLE_ID`/`APPLE_TEAM_ID`/`APPLE_APP_PASSWORD`; a `.app` and a `.dmg` get stapled, a bare executable cannot be, so the CLI's ticket is verified online.

`-t` runs the suites before anything is built, so a red test never produces an artifact. `-s core|app|all` selects the suites — `core` is `xcrun swift test` in AppBoxCore, `app` is the AppBoxTests test plan. Each suite runs under a watchdog (`-T`, default 1200s) because the AppBoxTests host can hang at launch in `DropboxSession.setup` on some machines; `-s core` sidesteps that.

**The CLI is not a single file.** `CoreDataStack` loads the compiled `AppBox.momd` out of `AppBoxCore_AppBoxCore.bundle`, which SwiftPM emits *next to the executable* — that is why the GUI copies both into `Contents/SharedSupport`. The standalone package therefore ships `appboxcli` + the bundle + an `install.sh` that puts both in `<prefix>/lib/appbox` and symlinks only the executable onto `PATH` (`Bundle.main.executableURL.resolvingSymlinksInPath()` is one of the stack's bundle-search candidates, so the symlink resolves correctly).

### Smoke tests (manual, before shipping)

- **GUI:** launch → Dropbox login → select a real `.ipa` → upload → confirm OTA manifest + short link → confirm Slack/Teams/email notification (where configured).
- **CLI:** on a machine **without the GUI**, `appboxcli --ipa <path> ...` uploads and prints the link; auth uses the shared Keychain token or its own OAuth. Subcommands: `upload`, `login`, `logout`, `whoami`, `space`, `list`, `delete`.
- **CLI matrix:** `Scripts/test_cli.sh [n,m,…]` runs the upload scenarios against your Dropbox; `APPBOX_CLI=<path>` tests a local build instead of the one on `PATH`. Tests 18–19 cover a nested `--dbfolder` with keep-same-link: the link stays the same, `list` shows the whole folder, and deleting the folder's only build (test 19, which is skipped while AppBox is running) leaves the parent folder's link intact.
- **Core Data:** launch GUI against a v4 store copy → existing projects/uploads load; a CLI upload then appears in the GUI Dashboard (shared store).

## Resume protocol (start of every session)

1. Read local `plans/follow-ups.md` (git ignored) for what is still open.
2. `git log --oneline develop` and `git status`.
3. Run the test plan to confirm the baseline is green.
4. Keep `plans/follow-ups.md` updated as you go (it is the durable source of truth, not chat).

## Conventions

- Match the style of surrounding code. New code is Swift; tests are Swift + hermetic (no real Keychain / NSUserDefaults / network / filesystem — use the in‑memory fakes in the test target and an in‑memory Core Data container).
- Don't commit or push unless asked. If asked, branch from `develop`, never commit on `master`.
- Commit messages: write them like a human author — concise, plain, present-tense subject; optional short body explaining the why. **Do not add any AI/Claude `Co-Authored-By` trailer or tool attribution.**
- Markdown: don't hard-wrap prose. Keep each paragraph, bullet, and blockquote on a single line so it reflows on any screen width (a soft line break renders as a space, so fixed-column wraps break awkwardly on mobile). Tables, code fences, admonitions, link-reference definitions, and explicit hard breaks (trailing `  ` or `\`) are exempt. GitHub issue templates (`.github/ISSUE_TEMPLATE/`) render in comment context where soft breaks become `<br>`, so leave their line breaks intact.
- Comments: write self-documenting code and keep comments minimal. Do NOT add narration or rationale comments that restate what the code does or explain why it's there. Remove such comments when you touch a file. KEEP only: (1) the minimal file header (filename / author / date) and any license/SPDX header; (2) `// MARK:` marks and tooling directives (`// swift-tools-version:`, `// swiftlint:…`, `// eslint-…`, `webpackChunkName`, `@ts-…`, etc.); (3) `///` doc comments — but keep each to a one-line summary, with short `- Parameter` / `- Returns` lines only where the meaning isn't obvious. Delete commented-out code and decorative separators outright.
