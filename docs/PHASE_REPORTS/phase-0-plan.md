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
