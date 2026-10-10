# Architecture decisions

Defaults below are the Section F project decisions. Status describes whether a decision has been validated in this repository, not whether every associated feature is implemented.

| # | Decision | Default | Status | Rationale |
|---|---|---|---|---|
| 1 | Knowledge model | E2EE; managed server-side rendering is separate and opt-in in Phase 7 | Accepted | The server should store ciphertext only by default. |
| 2 | Recipient app requirement | No for external clients in the Phase 7 web viewer; internal users use the app | Accepted | External access should not require an install. |
| 3 | Recovery | Show a recovery key once at vault creation and for each E2EE file; without it, recovery is not possible | Accepted | Make key-loss consequences clear while allowing a second wrapper. |
| 4 | Argon2 parameters | 64 MiB, t=3, p=2; configurable after benchmark | Pending benchmark | Record a real reference-device measurement before changing defaults; target 0.5–1 second. |
| 5 | PDF library | pdfx | Accepted | Open-license default; confirm the exact package license at Phase 2 dependency review. |
| 6 | Office rendering | Off; optional server rendering in Phase 5 with documented E2EE conflict | Accepted | Avoid sending E2EE plaintext to a renderer by default. |
| 7 | Product name | “BitLock” is a working name only | Pending clearance | Check trademark, Play Store, and domain availability before publication. |
| 8 | Multi-device conflicts | Append-only versions with owner-resolved branches | Accepted | Avoid silent replacement and preserve history. |
| 9 | Version signing keys | On-device Ed25519, Keystore-wrapped; publish public key | Accepted | Keep signing private keys on owner devices. |
| 10 | Managed key provider | Stub only until a KMS is chosen | Accepted | Avoid committing to a provider before requirements are known. |

## Phase 1 benchmark

Not measured: Dart/Flutter SDKs are not installed in the current environment. Run `dart run bin/bench_kdf.dart` from `packages/bitlock_core` on the reference mid-range Android device, then record device, OS, SDK, and elapsed time here.
