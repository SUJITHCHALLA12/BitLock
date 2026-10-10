# Phase 0 plan: foundations

## Files and structure

- Establish the monorepo root, `.gitignore`, `.editorconfig`, and shared CI workflow.
- Move the existing pure Dart implementation into `packages/bitlock_core` without keeping a second copy; expose its public API from `lib/bitlock_core.dart`.
- Add a minimal Flutter app package skeleton and shared lint configuration.
- Create the required threat model, security model, decision log, naming checklist, format documentation, dependency notes, and release map.

## Tests and checks

- Keep the existing core format and streaming tests in the core package, and make imports use the public barrel.
- Add a repository secrets-hygiene check and run it locally and in CI.
- Run `dart pub get`, `dart analyze`, `dart test`, `flutter pub get`, `flutter analyze`, and `flutter test` if the SDKs are available.
- Confirm required documents and workflow paths exist and review the documented threat lists and Section F decisions.

## Acceptance checks

- Monorepo layout and Git repository exist.
- Both required threat-model lists and all ten default decisions are documented.
- CI runs core and app analyzers/tests and repository secrets hygiene.
- Local checks pass, or the exact SDK/environment blocker is recorded. Do not begin Phase 1 until the Phase 0 gate is satisfied.

## Close-out follow-up — 2026-10-10

The user authorized completing the remaining Phase 0 and Phase 1 checks. Work
must still close Phase 0 before Phase 1 is accepted.

### Existing files to extend

- `app/lib/main.dart` and the existing widget test only if baseline checks
  expose a Phase 0 defect.
- `app/android/` only for build configuration necessary to produce a debug APK.
- This report with exact Flutter, analyzer, test, Android build, and secret-scan
  output.

### Checks

- From `app/`, run `flutter pub get`, `flutter analyze`, and `flutter test`.
- Build `flutter build apk --debug` if the installed JDK/Android SDK permit it;
  record blockers exactly if the build cannot complete.
- Confirm all foundation docs, Android scaffold files, and CI workflows exist.
- Run the repository secret scan and record its output.

### Risks and open questions

- This Windows environment's Android Studio uses Java 25, while the repository
  currently uses Gradle 8.14 / AGP 8.11.1; a compatible temporary JDK may be
  required. The NDK may also need installation.
- Do not mark a build passed based on a remote artifact or user report without
  an available build log or local output.

## Follow-up plan: Flutter Kotlin compatibility

The Android project was added after the original plan. The current build reports
that Kotlin 2.1.0 is below Flutter's minimum supported 2.2.20.

### Files to extend

- `app/android/settings.gradle`: raise the Kotlin Android Gradle plugin version
  from 2.1.0 to Flutter's reported minimum, 2.2.20.
- This plan and `phase-0-report.md`: record the targeted change and its actual
  build result.

### Checks

- Inspect the settings plugin declaration and confirm the old version is no
  longer present in Android Gradle configuration.
- Run `flutter build apk --debug` from `app/` to confirm the reported Kotlin
  compatibility error is resolved. Record any unrelated environment blocker
  without marking the Android build as passed.

### Risks and open questions

- The Kotlin Gradle plugin must remain compatible with the repository's
  committed Android Gradle Plugin and Gradle wrapper versions; the debug APK
  build is the acceptance check for that combination.
