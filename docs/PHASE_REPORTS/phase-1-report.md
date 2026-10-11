# Phase 1 report: cryptographic core

## Scope and status

The user explicitly authorized proceeding to Phase 1 while Phase 0 remained blocked. This report does not mark Phase 0 complete. Phase 1 implementation work is present, but Phase 1 is **not accepted** because the required Dart checks, CLI verification, lockfile generation, and commits could not be completed in this environment.

## Built

- Split crypto code into KDF, AEAD, key wrapping, and header-MAC modules, with a `bitlock_core` public barrel.
- Added Argon2id defaults of 65,536 KiB / 3 / 2, async isolate-based derivation, HKDF-SHA256 labels, and best-effort clearing of owned password, key, and plaintext byte buffers.
- Added authenticated header parsing, wrapped DEK, an encrypted metadata record, indexed AES-GCM data chunks, strict end-of-file validation, exclusive `.part` creation, overwrite refusal, and ciphertext preservation on failure.
- Added a password strength estimate and KDF benchmark command.
- Added binary type, round-trip, metadata privacy, wrong-password, tamper, same-file-ID splice, chunk-order, truncation, trailing-data, cleanup, overwrite, crypto-vector, and password strength tests.
- Added an RFC 5869 HKDF vector, a fixed header-MAC vector, and a tagged 512 MiB memory test wired to scheduled CI.
- Updated the format, threat, and security model documents.

## Verification results

| Check | Result |
|---|---|
| `dart pub get` | Blocked: `dart` is not installed/on PATH. No `pubspec.lock` was generated. |
| `dart analyze` | Blocked: `dart` is not installed/on PATH; clean analysis is unverified. |
| `dart test` | Blocked: `dart` is not installed/on PATH; test results are unverified. |
| `flutter analyze` | Blocked: `flutter` is not installed/on PATH. |
| KDF benchmark | Not run; no Dart SDK or reference Android device is available. Decision F4 remains pending. |
| 3 MiB CLI encrypt/decrypt, byte comparison, and tamper exit-code check | Not run; the Dart CLI cannot execute without the Dart SDK. |
| Secrets hygiene | Passed with Git Bash: `Secrets hygiene scan passed.` |
| Known-answer reference sanity check | Node's built-in HKDF-SHA256 and HMAC-SHA256 matched the committed expected vector values. This checks the vector values only; it does not verify the Dart implementation. |
| Git commits | Blocked: Git cannot create `.git/index.lock` because workspace policy denies writes to `.git`. |

## Format decisions and deviations

- The required encrypted metadata is encoded as one AEAD record immediately after the header and before data chunks. Its length is inferred from total file size minus the authenticated plaintext length and expected data chunk overhead, since the specified header has no metadata-length field. The plaintext metadata limit is 4 KiB. This is documented in `docs/FORMAT.md`.
- KDF input is capped at 256 MiB, 10 iterations, and 16 lanes, and chunk size is capped at 16 MiB. These documented bounds limit resource consumption from untrusted headers before the header MAC can be verified.
- The core provides an optional integrity observer seam without including paths or secrets. Owner notification and durable audit storage require a caller integration and are not implemented by the standalone CLI.
- The KDF benchmark result remains unrecorded, and no release status is claimed.

## Gate and remaining gaps

Do not begin Phase 2 until a Dart SDK is available and `dart pub get`, `dart analyze`, `dart test`, and the manual CLI checks pass; generated lockfiles are committed; the KDF benchmark is recorded; and Git metadata write access permits the required small commits. The Phase 1 code has not been compiled in this workspace, so source-level review is not a substitute for those checks.

## Verification follow-up — 2026-10-09

The SDKs became available for this session, so the earlier blocked checks were rerun after repairing the KDF buffer cleanup and test setup.

| Check | Result |
|---|---|
| Core `dart pub get` | Passed; generated `packages/bitlock_core/pubspec.lock`. |
| Core `dart analyze` | Passed: `No issues found!`. |
| Core `dart test --exclude-tags slow` | Passed: 27 tests passed; the separately skipped slow KDF test was reported as skipped. |
| Core `dart test --tags slow` | Failed the 512 MiB RSS assertion on Windows: peak 320,532,480 bytes, above the 268,435,456-byte limit. The round trip completed; the memory bound did not pass. |
| Slow-test selection | Fixed `dart_test.yaml`: its previous global exclusion made CI's scheduled `dart test --tags slow` select no tests. The CI job now can select the tagged large-file test. |
| Flutter `pub get`, `analyze`, and `test` | Passed; app analyzer reports no issues and the widget suite reports `+1: All tests passed!`. Generated `app/pubspec.lock`. |
| Android debug APK | Failed: Flutter reports the deleted Android v1 embedding. `app/android` has no Gradle project or application manifest, so there is no buildable Android target yet. |
| Connected devices | No Android device or emulator detected; only Windows, Chrome, and Edge were available. The reference-device KDF benchmark remains unrun. |
| Secret pattern scan | Native ripgrep scan found no likely credential assignments. The Bash wrapper now fails closed and returned status 2 because this environment's WSL shell cannot find `rg`. |
| CLI round-trip/tamper checks | Not run. |

Phase 1 remains **not accepted**. Resolve the large-file memory result on the Linux CI runner, run the CLI round-trip and tamper checks, and record the KDF result on a reference Android device. Phase 0 also remains open pending a verified Android debug build. No Phase 2 or protected-sharing work is claimed.

## Close-out verification — 2026-10-10

| Check | Result |
|---|---|
| Core dependencies | Passed: `dart pub get`. |
| Core analyzer | Passed: `No issues found!`. |
| Core regular suite | Passed: `dart test --exclude-tags slow`; 28 tests passed after a temporary default-chunk regression test, with the tagged slow test skipped. That temporary test and the unverified 1 MiB default experiment were removed. The final source retains the 64 KiB default. |
| Known-answer vectors | Passed: `dart test test/crypto_vectors_test.dart`; `+5: All tests passed!`. |
| 512 MiB streaming test | Not passed: the 1 MiB experiment encrypted the input but the test did not complete decryption. It was interrupted with 386,924,544 bytes in `large.out.part`, before its RSS assertion. No conclusion about the 256 MiB RSS bound can be drawn from this run. The earlier recorded failure remains: peak RSS 320,532,480 bytes. |
| CLI round trip and tampering | Not completed. The default-parameter CLI encryption remained CPU-bound in Argon2id for more than six minutes without producing the output container; it was stopped. No exit-code or cleanup result is claimed. |
| Reference-device KDF benchmark | Blocked: `adb devices -l` showed no attached device. |

No format, primitive, or known-answer vector changes were kept. Phase 1 remains
unaccepted until the slow test completes within its RSS bound, CLI checks finish,
and a reference-device KDF result is recorded. Phase 0's Android build is also
still blocked; Phase 2 remains out of scope.

## Independent verification — 2026-10-10 (Linux, Dart SDK 3.13.5)

At the user's request, the outstanding Phase 1 checks were run on a scratch copy of
this commit (repo files unchanged by the run):

| Check | Result |
|---|---|
| Core `dart pub get` | Passed (Dart SDK 3.13.5, linux_x64). |
| Core `dart analyze` | Passed: `No issues found!`. |
| Core `dart test --exclude-tags slow` | Passed: 27 passed, 1 skipped (slow KDF test). |
| CLI encrypt, 3 MiB input, production KDF params (64 MiB / t=3 / p=2) | Exit 0; container produced (3,147,436 bytes). |
| CLI decrypt, correct password | Exit 0; output byte-identical to input (`cmp`). |
| CLI decrypt, tampered container (1 byte flipped) | Exit 3 — "Decryption failed: invalid password or damaged file." No output file and no `.part` leftover. |
| CLI decrypt, wrong password | Exit 3 — same clean failure, no leftovers. |

Remaining open: the 3 MiB checks above are now complete; the tagged 512 MiB RSS
assertion is left to the scheduled CI `core-large-file` job (it failed on Windows
at 320,532,480 bytes peak vs the 268,435,456-byte bound), and the reference-device KDF benchmark is now measured (2026-10-11: 5605/5258/5022 ms, avg 5295 ms on the user's device — see `docs/DECISIONS.md`); F4 tuning decision (keep vs reduce params) is pending the user's call.
