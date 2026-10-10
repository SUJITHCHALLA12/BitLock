# Phase 0 report: foundations

## Built

- Initialized a Git repository and created the monorepo structure for the core, Flutter app, Supabase placeholders, documentation, CI, and scripts.
- Added the Phase 0 plan, root README, threat model, security model, ten Section F decisions, naming checklist, container format target, dependency license notes, and release map.
- Moved the inherited pure-Dart source, tests, and CLI under `packages/bitlock_core`; added the `bitlock_core` package barrel and recommended lints configuration.
- Added a minimal Flutter app package and widget test, plus CI jobs for the core, app, and secret scan.
- Added a source scan for likely hardcoded credentials.

## Checks and outcomes

| Check | Result |
|---|---|
| `git init` | Passed; repository created. |
| `dart pub get` | Not run successfully: `dart` is not installed/on PATH. |
| `dart analyze` | Not run successfully: `dart` is not installed/on PATH. |
| `dart test` | Not run successfully: `dart` is not installed/on PATH. |
| `flutter pub get` | Not run successfully: `flutter` is not installed/on PATH. |
| `flutter analyze` | Not run successfully: `flutter` is not installed/on PATH. |
| `flutter test` | Not run successfully: `flutter` is not installed/on PATH. |
| Secret scan | Passed with Git Bash: `Secrets hygiene scan passed.` A direct `rg --pcre2` check also found no likely credential assignments. |
| Git commits | Blocked by workspace permissions: Git could not create `.git/index.lock` (`Permission denied`). No commits were created. |

No dependency lockfiles could be generated without Dart/Flutter. CI is configured to resolve dependencies and run the analyzers and tests on pushes and pull requests, but this is not a substitute for local verification.

## Acceptance and gate

The repository structure and required foundation documents are present. The required local analyzers and tests have not passed because both SDKs are unavailable. The workflow has not been exercised locally. The required small commits are also blocked because the `.git` directory is readable but not writable through this workspace.

Phase 0 remains **blocked at the gate**. The user explicitly directed continuation into Phase 1; that instruction is recorded in the Phase 1 plan and does not mark Phase 0 complete. A Dart and Flutter SDK, generated package lockfiles, passing local checks, and Git metadata write access are still required to close this phase.

## Deviations and known gaps

- The app is a minimal Flutter shell; Flutter-generated Android project files were not generated because Flutter is unavailable. An Android source placeholder directory is present.
- The inherited core is relocated but not accepted as Phase 1. Its format still needs reconciliation with encrypted metadata, known-answer vectors, benchmarking, and the full tamper matrix in the new specification.
- No phase is marked complete and no release is claimed.

## Next phase needs

After the Phase 0 gate is cleared, complete Phase 1 against `docs/FORMAT.md`, update the format document alongside code and vectors, add missing security tests and the KDF benchmark, then run the complete Dart gate before proceeding.

## Verification follow-up — 2026-10-09

Dart 3.13.5 and Flutter 3.47.6 were available in a later session. Core and app dependency resolution succeeded and generated their package lockfiles. Core analysis and the non-slow suite passed; Flutter analysis and the widget test passed. The tagged 512 MiB stream test exceeded its RSS limit on Windows, and the Android APK build failed because the Android Gradle project and manifest are absent. No Android device or emulator was detected. The earlier table records the original environment accurately; these later results do not close the Phase 0 gate. Git metadata remains unwritable, and there is still no runnable Android APK.

The Bash secret-scan wrapper was also rerun after hardening: it now exits with status 2 when WSL cannot find `rg`, instead of incorrectly printing success. A direct native ripgrep scan found no likely credential assignments.

## Kotlin compatibility follow-up — 2026-10-10

- Updated `app/android/settings.gradle` from Kotlin Android Gradle plugin 2.1.0
  to 2.2.20, matching the minimum version reported by Flutter 3.47.6.
- `rg` confirmed there are no remaining 2.1.0 references in `app/android`.
- `flutter build apk --debug --verbose` reached the Gradle wrapper distribution
  download (`gradle-8.14-bin.zip`), but the download remained at 0 bytes for
  more than three minutes. The build was stopped before Gradle or the Kotlin
  plugin could run, so APK compilation remains unverified; this is an
  environment/network blocker, not a passing build result.
- Flutter's automatic Android migration temporarily modified
  `gradle.properties` and generated wrapper files during the attempt. Those
  unrelated generated changes were discarded; the Kotlin version edit is
  retained.
- The prior Phase 0 blockers remain open.
