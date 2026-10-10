# BitLock

BitLock is a planned zero-trust file protection platform: an Android-first Flutter app, a pure Dart encryption core, and a Supabase backend. The default cloud model is end-to-end encryption. Phase 0 foundations exist and Phase 1 core work is underway; neither phase has passed its acceptance gate, and no release is complete.

The core is designed for any file type, with encrypted filename, MIME type, and creation-time metadata. Planned previews are PDF, images, and text, with archive listing later. Other formats remain protected opaque files. See [the threat model](docs/THREAT_MODEL.md) for protections and limits.

## Packages

- Core: `cd packages/bitlock_core`, then `dart pub get`, `dart analyze`, and `dart test`.
- Android app: `cd app`, then `flutter pub get`, `flutter analyze`, and `flutter test`.
- Repository secret scan: `bash scripts/check_secrets.sh`.

The SDKs must be installed before these commands can run. Each Dart package has its own dependency lockfile. Do not treat the inherited pre-monorepo crypto code as Phase 1 accepted until it has passed the Phase 1 gate.

## CLI

Run `dart run bin/bitlock_cli.dart encrypt <input> <output.bitlock>` or `dart run bin/bitlock_cli.dart decrypt <input.bitlock> <output>` from `packages/bitlock_core`.

## What BitLock does not protect against

See the complete “BitLock cannot guarantee protection against” list in [docs/THREAT_MODEL.md](docs/THREAT_MODEL.md). It includes camera photography, compromised or rooted devices, memory inspection after authorized decryption, deliberate sharing or retyping of visible content, unsupported capture paths, and plaintext already exported.
