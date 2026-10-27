# Phase 2 — UI implementation report

Date: 2026-10-27. Scope: complete the BitLock Flutter UI in `app/`
on top of the Phase 2 draft screens. No changes to
`packages/bitlock_core`. Nothing in this report was compiled or
test-run on the authoring machine — see "Verification status".

## Verification status (honest)

**UNCOMPILED.** The authoring VM has no Flutter/Dart SDK, so
`flutter analyze`, `flutter test`, and `flutter build` could NOT be
run. All Dart was written to the style of the existing draft files
(flutter_lints, doc comments on public members, trailing commas,
single quotes) and checked by hand for API compatibility with the
existing widget tests. Treat every item below as
"implemented, not yet verified" until these commands pass on a
machine with the SDK:

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Known-answer/core suites are untouched and should also still pass:

```bash
cd packages/bitlock_core && dart analyze && dart test
bash scripts/check_secrets.sh
```

## What was built, file by file

### Design system and shared widgets
- `app/lib/theme/bitlock_theme.dart` — `BitLockColors` (deep navy
  `0xFF0E0B1E`, surface `0xFF1B1533`, violet primary `0xFF7C4DFF` /
  `0xFF8B5CF6`, accent, error, success, warning) and
  `BitLockTheme.dark()` (complete `ThemeData`: dark colour scheme,
  scaffold, app bar, card, input decoration, filled/outlined
  buttons, chips, navigation bar, snack bar, dialog) plus a minimal
  `BitLockTheme.light()`.
- `app/lib/widgets/bitlock_widgets.dart` — `BitLockPrimaryButton`
  (busy spinner state), `BitLockSearchField`, `EmptyStateView`,
  `StatusChip`, `StatCard`, `SectionHeader`, and
  `showConfirmDialog(context, {title, message, confirmLabel, destructive})`.

### Onboarding (`app/lib/features/onboarding/`)
- `splash_screen.dart` — `SplashScreen({onDone})`; shield branding,
  tagline, loading indicator; `Timer` (~1.6 s) cancelled in
  `dispose`.
- `onboarding_screen.dart` — `OnboardingScreen({onGetStarted,
  onAlreadyHaveVault})`; 3-page `PageView` (local encryption;
  controlled sharing with the view-only limits stated plainly;
  forgotten-password warning), dots, Next/Skip, final
  "Create my vault" button, "I already have a vault" route.
- `create_vault_screen.dart` — `CreateVaultScreen({onCreate})`;
  password + confirm with show/hide, live strength label explicitly
  labelled "rough guide", mismatch error, required
  forgotten-password checkbox, Create disabled until valid, busy
  state, generic failure text. No default password anywhere.

### Vault (`app/lib/features/vault/`)
- `vault_entry.dart` — extended with optional `lastAccessedAt` and
  `mimeLabel`; all existing fields, `sizeLabel`, and the const
  constructor unchanged.
- `unlock_vault_screen.dart` — upgraded in place. Constructor stays
  compatible (`UnlockVaultScreen({onUnlock})` still compiles);
  added optional `onBiometricUnlock`, `onAuthenticated`, and
  `maxAttempts`. Shield branding, show/hide toggle, failed-attempt
  counter ("N failed attempt(s)", with "of M" when a budget is
  given), biometric button only when the callback is provided.
  Exactly one `TextField`, and the error string is unchanged:
  "Couldn't open the vault. Check your password and try again."
- `vault_home_screen.dart` — converted to a `StatefulWidget` with
  the identical constructor. Adds internal search field (filters by
  name), sort popup (Name A–Z / Newest / Oldest / Largest), type
  filter chips (All / PDF / Images / Text / Other), result count,
  and a "No files match your search" state distinct from the empty
  vault. Default view still lists every entry untouched; the "My
  vault" title and "Add file" FAB label are unchanged.
- `file_details_screen.dart` — metadata rows (name, type incl. MIME
  label, size, added, last accessed, active share count), factual
  security card, View / Create share / Rename / Export / Delete.
  Export first shows a warning dialog (exported copy is no longer
  protected by BitLock) and calls `onExport` only after explicit
  confirmation; rename validates non-empty in a dialog; delete
  requires a destructive confirmation.
- `import_file_screen.dart` — `PickedFileInfo({name, sizeBytes,
  mimeLabel})` and `ImportFileScreen({onPickFile, onConfirmImport})`.
  The caller owns the SAF picker (stated in the doc comment); the
  screen shows the picked file, states the original is not deleted
  or modified, lists supported types as bytes-opaque, shows a busy
  state during import, a success check state with a Done button
  that pops `true`, and an error state on `false`. It never reports
  success unless `onConfirmImport` returns `true`.

### Sharing (`app/lib/features/share/`)
- `share_models.dart` — `ShareStatus` (active/expired/revoked/
  exhausted/pending), `SharePermission` (viewOnly/viewAndExport),
  `ShareGrant` (with `isActive`, `statusLabel`, `expiryLabel`,
  `permissionLabel`, `accessLabel`), `ShareDraft`, and
  `sampleShareGrants()` labelled preview-only.
- `create_share_screen.dart` — permission option tiles (view-only
  tile states that BitLock provides no download in view-only mode
  and that FLAG_SECURE blocks supported capture paths but cannot
  stop a camera), expiry choices (1 hour / 24 hours / 7 days /
  No expiry — No expiry requires an extra confirmation checkbox),
  one-time toggle fixing the limit at 1 and disabling the stepper,
  access-limit stepper, optional passcode with show/hide and a
  "not stored in plaintext" note. On `onCreate` returning a link:
  link shown with a Copy button (`Clipboard.setData`). On null:
  "Share could not be created. The sharing backend may not be
  configured yet." No link is ever invented locally.
- `share_management_screen.dart` — status filter chips
  (All/Active/Expired/Revoked/Exhausted), rows with file name,
  `StatusChip`, expiry, accesses used/limit, permission, passcode
  marker; Copy link for active grants; Revoke only for active
  grants, behind a confirmation, reflected in the UI only when
  `onRevoke` returns `true`, otherwise the snackbar "Revocation was
  not confirmed by the server." Optional `backendConfigured`
  (default `true`); when false, a banner reads "Sharing backend is
  not configured — shares cannot be created or changed yet."
- `received_files_screen.dart` — `RedeemResult` enum (success,
  expired, revoked, exhausted, invalid, authFailed,
  backendUnavailable) each with a distinct user message. Local
  format validation first: the link must start with
  `bitlock://share/` with a token segment, or be an `https://` link
  with a token segment; otherwise "This does not look like a
  BitLock share link." is shown and `onRedeem` is NOT called.
  Optional passcode field; busy state; per-result result card.
  Optional `incomingShares` list rendered as "Shared with you".

### Dashboard (`app/lib/features/dashboard/dashboard_screen.dart`)
- `DashboardScreen` with the specified constructor plus an optional
  `statusLabel` defaulting to "Vault unlocked · files stored
  encrypted on this device". Header, status card, three stat cards
  (protected files = `entries.length`; active shares = count of
  `status == active`; storage = sum of `sizeBytes`, formatted),
  quick actions (Import File / My Vault / Shared / Received), up to
  5 recent files, up to 3 recent security events. All numbers are
  derived from the passed data; no security score is shown.

### Settings (`app/lib/features/settings/settings_screen.dart`)
- `BitLockSettingsData` (autoLockMinutes default 5,
  biometricUnlock, notificationsEnabled, darkTheme default true)
  with `copyWith`. `SettingsScreen` with working auto-lock dropdown
  (Immediately / 1 / 5 / 15 / 30 min), biometric, notifications and
  theme switches — every control updates state and calls
  `onChanged`. Storage row from `storageUsedLabel`; "Clear
  temporary files" calls `onClearTempFiles` and snacks "Cleared N
  temporary files" with the returned count; rows pushing share
  management and security activity; About section with version and
  a "Privacy & security" dialog summarising ciphertext-only
  backend, view-only limits, and FLAG_SECURE limits.

### App shell and entry
- `app/lib/app/bitlock_shell.dart` — `BitLockShell` (NavigationBar:
  Dashboard / Vault / Shared / Received / Settings over an
  `IndexedStack`; dashboard navigation callbacks switch tabs;
  settings "Manage share links" / "Security activity" push the real
  screens; a Lock FAB calls `onLock`) and `BitLockRoot`
  (splash → onboarding → create, or unlock when a vault exists →
  shell; locks back to unlock).
- `app/lib/main.dart` — `BitLockApp` now uses `BitLockTheme.dark()`
  and mounts `BitLockRoot`. A prominent doc comment states this is
  UI-preview wiring: with no callbacks supplied, the root accepts
  any non-empty password and uses sample data, purely to walk the
  UI; production wiring must derive keys via `bitlock_core`
  Argon2id (returning `false` on failure) and feed real store data.
  The 'BitLock foundation' placeholder is gone.

### Android
- `MainActivity.kt` — `bitlock/security` `MethodChannel` handler:
  `setFlagSecure(bool)` adds/clears `FLAG_SECURE` on the UI thread.
  This completes the Android side that the draft `SecureScreen`
  widget already called.
- `AndroidManifest.xml` — `android:usesCleartextTraffic="false"`
  and `android:allowBackup="false"` on `<application>`; a
  VIEW/BROWSABLE/DEFAULT intent filter for `bitlock://share/...`
  on MainActivity; the launcher filter is unchanged.

### Tests
- `app/test/bitlock_ui_test.dart` (new): dashboard counts derived
  from given data; create-share one-time toggle produces
  `accessLimit == 1` and shows the returned link; create-share
  failure shows the error and no link; received screen rejects a
  malformed link locally (`onRedeem` not called); settings toggle
  fires `onChanged` with the flipped value; create-vault mismatch
  error with Create disabled; file-details export gated behind the
  confirmation dialog; vault home search filters the list.
- `app/test/app_test.dart` (updated): the 'BitLock foundation'
  expectation was replaced — `BitLockApp` is pumped and the splash
  'BitLock' text is expected, then the splash timer is flushed and
  onboarding is expected. A comment in the file explains the change,
  per the repo rule on test changes.
- `app/test/phase2_screens_test.dart` — NOT modified. All of its
  constructor calls and expectations were checked against the new
  code by hand (see "Compatibility" below).

### Docs
- `SECURITY.md` (repo root, new) — short trust-boundary and
  limitations summary pointing at `docs/SECURITY_MODEL.md` and
  `docs/THREAT_MODEL.md`.

## Acceptance status (honest, per item)

- Placeholder screens replaced with real UI flows: **implemented**
  (all screens above), unverified until analyze/test run.
- Main navigation works: **implemented** (BitLockShell tabs +
  root state machine), unverified on device.
- File selection through the system picker: **UI implemented**;
  the SAF picker itself is the caller's callback (`onPickFile`)
  and is not yet wired to a platform picker.
- Encryption/decryption, wrong-password and corruption handling:
  **unchanged** — provided by `bitlock_core`; the UI surfaces the
  core's generic failure and never fakes success. Wiring the
  callbacks to the core is still to do.
- Persistence across restarts: **not yet** — the shell preview uses
  in-memory sample data; the vault metadata store is still to be
  connected.
- Controlled viewing: draft viewers unchanged (text/image in
  memory, watermark, FLAG_SECURE via `SecureScreen`); PDF page
  rendering still awaits the pdfx dependency decision already
  recorded in the Phase 2 plan.
- Export gating: **implemented in UI** (confirmation dialog before
  `onExport`).
- Share creation/redemption against a real backend: **UI
  implemented; backend NOT configured.** With the shipped preview
  wiring, create returns null (error state shown) and redeem
  returns `backendUnavailable`; management shows the
  not-configured banner. Server-side expiry/revocation/access-limit
  enforcement belongs to `backend/supabase/` and remains to be
  connected and tested there.
- Secrets in UI/logs: none added; settings and diagnostics copy
  explicitly excludes keys/passwords/tokens.
- App assembles with the existing toolchain: **unknown** until
  `flutter build apk --debug` runs on an SDK machine.

## Compatibility notes

- All Phase 2 draft signatures are preserved: `VaultHomeScreen`,
  `UnlockVaultScreen` (new params optional), `TextViewerScreen`,
  `ImageViewerScreen`, `PdfViewerScreen`, `AuditLogScreen`,
  `AuditLogEntry`, `VaultEntry` (new fields optional),
  `sampleVaultEntries()`. `audit_log_screen.dart` and the viewer
  screens were left untouched.
- `VaultHomeScreen` changed from `StatelessWidget` to
  `StatefulWidget` (same constructor) to hold search/sort/filter
  state internally, as required — no caller changes needed.
- One risk to check at first analyze: `CardThemeData` /
  `DialogThemeData` in `bitlock_theme.dart` assume a current
  Flutter (3.29+). On an older SDK these two theme slots take the
  pre-3.29 types and would need adjusting.

## Open questions

1. Vault metadata plaintext decision (from the Phase 2 plan) is
   still open — `VaultEntry.name` visibility before unlock affects
   what the dashboard/vault may show pre-unlock.
2. Which callbacks does the store layer land first: SAF picker +
   core encrypt on import, or unlock wiring? The UI is ready for
   either order.
3. pdfx: license already cleared (see Phase 2 plan); pinning the
   version in `pubspec.yaml` and recording it in
   `docs/DEPENDENCIES.md` is still pending — deliberately not done
   here to avoid an unverifiable dependency change.
4. Deep links currently only declare the intent filter; routing an
   incoming `bitlock://share/...` link into the Received tab is
   app-links/plugin wiring still to do.
