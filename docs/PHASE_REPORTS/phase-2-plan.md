# Phase 2 plan: local vault + secure viewer

Scope is v0.1 per `docs/MVP_RELEASES.md`: local vault, PDF/image/text viewer,
FLAG_SECURE, watermark, local audit. No temporary or one-time shares, no cloud,
no collaboration — those belong to later phases. Builds on the Phase 1
cryptographic core (`packages/bitlock_core`); no container-format changes.

## Files to create or extend

- `app/lib/features/vault/`: vault home screen, file list, add-file flow
  (encrypt via `bitlock_core`), unlock-vault with password. Currently only
  `.gitkeep` placeholders exist.
- `app/lib/features/viewer/`: PDF viewer, image viewer, text viewer. Decrypted
  bytes are rendered in memory only — never written as plaintext to disk.
  Viewer routes set FLAG_SECURE.
- `app/lib/features/audit/`: local append-only audit log (hash-chained) plus a
  viewer screen. Log records vault open, file view, and export decisions.
- `app/lib/security/`: watermark overlay widget and a secure-screen helper that
  applies FLAG_SECURE on viewer routes.
- `app/lib/data/local/`: vault metadata store and audit-log storage. Document
  exactly which metadata is kept in plaintext (e.g. filenames) and why.
- `app/pubspec.yaml`: re-add the `bitlock_core` path dependency; add `pdfx`
  for PDF rendering (decision F5: confirm the exact package license at the
  Phase 2 dependency review).
- `docs/DEPENDENCIES.md`: record `pdfx` (purpose, license, last release date,
  why this package).
- `docs/THREAT_MODEL.md` / `docs/SECURITY_MODEL.md`: update only if the viewer
  or audit additions change the documented assumptions.

## Tests to write (including negative tests)

- Widget tests: vault home renders, add-file flow completes, viewer screens
  open for PDF/image/text, watermark widget is present on viewed content.
- Audit tests: appending works; a tampered log entry is detected via the hash
  chain; there is no edit/delete API on the log.
- Negative: decrypt with wrong password from the vault UI surfaces the generic
  integrity failure (no partial plaintext, no detailed error).
- Viewer cleanup: closing a viewer releases decrypted bytes (best-effort
  clearing, same standard as the core).
- Keep the existing `app/test/app_test.dart` passing.

## Acceptance checks

- `cd app && flutter pub get && flutter analyze && flutter test` — zero analyzer
  issues, all tests pass.
- `flutter build apk --debug` (or `--release`) succeeds.
- On a physical device: create vault → add a file → view it as PDF/image/text →
  watermark visible → screenshot attempt blocked on the viewer (FLAG_SECURE) →
  audit log lists the open/view events.
- `bash scripts/check_secrets.sh` from the repo root is clean.
- `docs/DECISIONS.md` F5 (pdfx license) resolved at the dependency review.

## Stop condition

Do not start Phase 3 (cloud, protected links, expiry, revocation). Phase 2 is
done when every acceptance check above shows a real result in
`docs/PHASE_REPORTS/phase-2-report.md`.

## Risks and open questions

- FLAG_SECURE blocks screenshots on standard Android but not every capture path
  (rooted devices, external cameras). Per repo rules, UI copy must say
  "blocks supported capture paths", never "screenshot-proof".
- The 512 MiB streaming RSS test is still pending the scheduled CI run. If it
  forces a core streaming fix later, the fix stays inside `packages/bitlock_core`
  and does not change the Phase 2 UI contract.
- Vault metadata plaintext tradeoff (filenames visible without unlock?) needs an
  explicit documented decision before the vault store is built.
- pdfx: confirm license and maintenance status before adding the dependency.
