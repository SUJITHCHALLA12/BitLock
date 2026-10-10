# Implementation Plan

## Current state

BitLock has a pure Dart Phase 1 container core, a minimal Flutter shell, and Supabase directory placeholders. The Phase 0 and Phase 1 acceptance gates remain open. The local Dart 3.13.5 and Flutter 3.47.6 SDKs are installed; no BitLock GitHub repository or local Git remote is configured.

## Active increment: close the Phase 1 core gate

Keep this increment limited to the existing Dart cryptographic core. Fix analyzer and runtime failures found in the current implementation without changing the version 1 container format. Preserve the independent AEAD, header authentication, streaming, metadata privacy, failure cleanup, and ciphertext-preservation contracts.

### Files in scope

- Extend `packages/bitlock_core/lib/src/crypto/kdf.dart` to make temporary KDF output safely clearable.
- Extend `packages/bitlock_core/test/bitlock_streaming_test.dart` and `test/large_streaming_test.dart` to restore compilation and correct slow-test tagging.
- Make `scripts/check_secrets.sh` fail closed when `rg` is missing or the scan itself errors.
- Update the Phase 1 report with actual analyzer and test results after verification.

### Acceptance checks

- `dart pub get`, `dart analyze`, and `dart test` from `packages/bitlock_core`.
- `dart test --tags slow` only when explicitly running the scheduled large-file test.
- Run the CLI round-trip and tamper-cleanup checks from the Phase 1 report if the environment permits.
- Do not advance to Phase 2 while Phase 1 checks, the reference-device KDF benchmark, or the Phase 0 gate remain unresolved.

### Risks and open items

- Dependency resolution and Dart commands may require network or SDK access outside the sandbox.
- The KDF benchmark still needs a documented reference Android device and result.
- Android project generation and build configuration are not present yet; app integration belongs to a later phase.
- Supabase OAuth is configured in the user's CLI, but no Supabase tools or BitLock GitHub repository are connected to this session.

## Latest verification status

- Core analysis and the non-slow suite pass (27 passed, 1 intentionally skipped).
- The tagged 512 MiB Windows run exceeded the 256 MiB RSS limit; resolve this against the Linux CI runner before closing Phase 1.
- Flutter analysis and widget tests pass, but `flutter build apk --debug` fails because the Android Gradle project and manifest are missing.
- No Android device/emulator is connected, so the reference-device KDF measurement and Phase 1 acceptance remain open.
