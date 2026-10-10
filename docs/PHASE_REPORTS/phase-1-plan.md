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
