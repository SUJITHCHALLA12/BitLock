# Architecture decisions

Defaults below are the Section F project decisions. Status describes whether a decision has been validated in this repository, not whether every associated feature is implemented.

| # | Decision | Default | Status | Rationale |
|---|---|---|---|---|
| 1 | Knowledge model | E2EE; managed server-side rendering is separate and opt-in in Phase 7 | Accepted | The server should store ciphertext only by default. |
| 2 | Recipient app requirement | No for external clients in the Phase 7 web viewer; internal users use the app | Accepted | External access should not require an install. |
| 3 | Recovery | Show a recovery key once at vault creation and for each E2EE file; without it, recovery is not possible | Accepted | Make key-loss consequences clear while allowing a second wrapper. |
| 4 | Argon2 parameters | 64 MiB, t=3, p=2; configurable after benchmark | Measured 2026-10-11: ~5.8 s avg over 9 runs on user device (5-8x over target); tuning decision pending | See Phase 1 benchmark section below. |
| 5 | PDF library | pdfx | Accepted | Open-license default; confirm the exact package license at Phase 2 dependency review. |
| 6 | Office rendering | Off; optional server rendering in Phase 5 with documented E2EE conflict | Accepted | Avoid sending E2EE plaintext to a renderer by default. |
| 7 | Product name | “BitLock” is a working name only | Pending clearance | Check trademark, Play Store, and domain availability before publication. |
| 8 | Multi-device conflicts | Append-only versions with owner-resolved branches | Accepted | Avoid silent replacement and preserve history. |
| 9 | Version signing keys | On-device Ed25519, Keystore-wrapped; publish public key | Accepted | Keep signing private keys on owner devices. |
| 10 | Managed key provider | Stub only until a KMS is chosen | Accepted | Avoid committing to a provider before requirements are known. |

## Phase 1 benchmark

Measured 2026-10-11 on the user's physical Android device via the temporary
in-app benchmark screen (3x `deriveKeys` with default `KdfParams` per session,
timed on-device, app built from main @ 8764d6bc via `flutter run` in debug).
Three sessions, nine runs total:

- Session 1: 5605 / 5258 / 5022 ms (avg 5295 ms)
- Session 2: 8549 / 5690 / 6698 ms (avg 6979 ms)
- Session 3: 5526 / 4970 / 4949 ms (avg 5148 ms)
- Overall: ~5.0–8.5 s per derivation, averaging ~5.8 s

Device: Redmi 9i (M2006C3LII), MediaTek Helio G25 — entry-level hardware, which explains the slow pure-Dart Argon2id. Android version: not recorded.

Finding: the default 64 MiB / t=3 / p=2 parameters take ~5–8 s per derivation on
this device — roughly 5–8x over the 0.5–1 s target. First runs of a session skew
higher (cold start); settled runs sit near ~5 s. Tuning decision pending user call:
keep the stronger defaults (slow ~5 s unlock) or reduce parameters toward the target
(faster unlock, less brute-force resistance).
