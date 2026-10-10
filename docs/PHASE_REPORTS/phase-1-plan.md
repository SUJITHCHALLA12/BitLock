# Phase 1 plan: cryptographic core

The user explicitly directed work to continue with Phase 1 although Phase 0 was reported blocked. Phase 0 blockers remain open and are not treated as passed.

## Files to create or update

- Refactor `packages/bitlock_core/lib/src/crypto/` into focused KDF, AEAD, key wrapping, and header MAC modules; retain the public package barrel.
- Implement encrypted metadata and strict container parsing in `src/format/`, and bounded-memory encrypt/decrypt in `src/streaming/`.
- Add a password-strength estimate, public metadata/result types, and document best-effort key clearing.
- Add `bin/bench_kdf.dart`, keep the CLI, add format/security docs and known-answer vectors.
- Expand tests for binary types, metadata, tamper cases, key derivation, header MAC, strength scoring, and tagged 512 MiB streaming memory use.

## Tests and acceptance checks

- Write negative tests for every authenticated structure before relying on the corresponding behavior.
- Run `dart pub get`, `dart analyze`, and `dart test` in the core package.
- Run the 3 MiB CLI round trip, byte comparison, and tampered-file exit-code/output-cleanup checks.
- Record KDF benchmark device and result in `docs/DECISIONS.md` when a reference device and SDK are available.

## Stop condition

Do not start Phase 2. Report any check blocked by missing tools or environment and leave Phase 1 unaccepted until every acceptance check passes.

## Close-out follow-up — 2026-10-10

After Phase 0 is closed, resolve the outstanding Phase 1 checks without
changing the version 1 container format or known-answer vectors.

### Existing files to extend

- `packages/bitlock_core/lib/src/streaming/bitlock_streaming.dart` only if the
  baseline large-file run confirms the memory regression and a targeted fix is
  justified by inspection.
- Keep the current 64 KiB default unless a completed isolated slow test
  demonstrates that changing it addresses the measured failure. A trial with
  1 MiB chunks did not complete the slow test and was reverted.
- Keep `docs/FORMAT.md`, the version 1 layout, and both known-answer vector
  files unchanged unless a completed test justifies a documented change.
- Existing streaming tests and CLI only when needed to cover a proven defect;
  preserve all current assertions.
- `docs/DECISIONS.md` only if a real reference Android KDF benchmark can be
  collected, and this report with exact outputs for every acceptance check.

### Checks

- In the core package, run `dart pub get`, `dart analyze`, `dart test`, and
  `dart test test/vectors_test.dart`.
- Run the tagged 512 MiB streaming test and keep its RSS result.
- Run the 3 MiB CLI encrypt/decrypt comparison and tampering cleanup check.
- Check for a connected Android device and run the KDF benchmark on a
  reference device if available; otherwise record the device requirement as
  BLOCKED.
- Search all callers before changing any function and rerun affected tests.

### Risks and open questions

- The prior report says the Windows large-file test exceeded its 256 MiB RSS
  bound. The 1 MiB trial encrypted the file, then stalled during decryption at
  386,924,544 bytes of staged plaintext; it did not reach the test assertion.
  It therefore neither confirms nor fixes the RSS failure and was reverted.
- The first isolated run took over 15 minutes and was interrupted during
  decryption. Its output cleanup failed because the test process still held the
  temporary directory. Optimize record count only if the baseline confirms the
  bounded-memory/throughput issue; then rerun the full slow test.
- The reference-device benchmark may remain blocked when no Android device is
  attached; do not fabricate a measurement or adjust KDF defaults without it.
