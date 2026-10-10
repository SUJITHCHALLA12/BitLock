# BitLock — Master Implementation Prompt for Codex

> **How to use:** Open the BitLock project folder in Codex, enable the appropriate repository/filesystem tools, and paste the entire prompt below. If no Android project exists yet, Codex should create one. If a project already exists, Codex must inspect and extend it rather than blindly replacing it.

---

## MASTER PROMPT — BUILD BITLOCK

You are acting as a senior Android engineer, application-security engineer, cryptography integrator, backend engineer, test engineer, and product designer. Build **BitLock**, a serious Android-first encrypted file-protection application. Treat it as a real security product, not just a UI demo.

Your work must be practical, incremental, testable, and honest. Do not claim a security guarantee unless the implementation actually provides it. Do not use homemade encryption, fake security toggles, hardcoded secrets, simulated success states, or mock cloud behavior presented as production functionality.

# 1. Product mission

BitLock protects files such as PDF, DOC/DOCX, PPT/PPTX, XLS/XLSX, TXT, CSV, images, videos, audio, ZIP, RAR, 7Z, source code, executables, and arbitrary binary files. The app must treat source files as bytes and must not need to understand a file format simply to encrypt or decrypt it.

The product direction is a **zero-trust file-protection platform** with two distinct areas:

1. **Local Vault:** offline encryption/decryption and local protected-file management.
2. **Protected Sharing:** online, time-limited and revocable access to encrypted files, with identity and access policies. This requires a real backend; do not simulate it or falsely label a local-only link as remotely revocable.

The first deliverable is a working and well-tested Android MVP. Implement the local vault and cryptographic file-container workflow first. Create clean, testable interfaces for future sharing/cloud functionality. Only implement live online features when the backend is genuinely configured and its security controls can be enforced.

# 2. Security claims and hard limits

These are non-negotiable product rules:

- Never implement a custom cipher, custom XOR obfuscation, homemade cryptographic protocol, or “bit scrambling.” Use established cryptographic libraries and documented primitives.
- Use authenticated encryption so unauthorized ciphertext or metadata modification is detected during decryption. Do not return partially decrypted output as if it were valid.
- Encrypt large files as streams; do not load an entire large file into RAM.
- A stolen `.bitlock` ciphertext file must not reveal plaintext without an appropriate decryption key/password.
- An authenticated ciphertext-integrity failure must stop decryption, remove incomplete plaintext output, and report an integrity error. **Do not destroy the user's original or encrypted file as a punishment.**
- Password protection on a standalone offline file cannot prevent an attacker from making unlimited offline password guesses. Use a strong password-based key derivation function and clearly warn users about weak passwords.
- “One-time access” can be enforced globally only by an online authority that atomically consumes a grant, or locally within the same trusted app/device state. It cannot be reliably enforced for a freely copied standalone file with no server.
- A URL is not theft-proof merely because it is encrypted. Treat a share link as a bearer credential unless recipient authentication is required. Do not put raw passwords, private keys, or file-encryption keys in ordinary URLs, query strings, logs, analytics, or crash reports.
- No mobile app can guarantee that a recipient will never copy information after it is displayed. Screenshot blocking, clipboard restrictions, no-download viewing and watermarks are deterrents/controls, not absolute guarantees. A camera outside the device cannot be controlled by the app.
- Revocation can stop future authorized access and future session renewal, but it cannot recall plaintext or keys already exported by an authorized recipient.
- Do not claim BitLock is “unhackable,” “impossible to copy,” “military grade,” “zero knowledge,” “end-to-end encrypted,” or “tamper-proof” unless the relevant implementation and threat model substantiate that exact claim.
- Do not use remote server rendering that exposes plaintext and simultaneously claim the server can never see plaintext. Clearly separate any future E2EE design from a server-controlled document viewer.
- Security must fail closed. If the app cannot confirm authorization, integrity, expiry, or key availability, deny the operation and explain why.

# 3. First actions: inspect before changing

Before coding:

1. Inspect the entire repository tree, README, Gradle files, manifest, existing modules, tests, CI configuration, signing/build setup, and any project instructions such as `AGENTS.md`.
2. Detect whether this is an existing Android project, an empty directory, or a multi-project repository. Preserve existing user work and project conventions.
3. Identify the current package/application ID, Kotlin version, Android Gradle Plugin version, Compose configuration, min/target SDK, Java toolchain, dependency catalog, and available build tools.
4. Use official, current documentation for library setup and compatible versions. Do not blindly paste obsolete dependency versions. Keep dependency versions centralized where the project supports it.
5. If a required tool, dependency repository, SDK, emulator, secret, or network is unavailable, record the limitation. Do not pretend a build/test/API call succeeded.
6. Write `docs/IMPLEMENTATION_PLAN.md` before large changes. Then implement the first vertical slice immediately rather than stopping after planning.
7. Maintain `docs/SECURITY_MODEL.md`, `docs/THREAT_MODEL.md`, and `docs/KNOWN_LIMITATIONS.md` as features are implemented.

Do not ask the user broad questions that are not blocking. Make safe defaults, document assumptions, and continue. Ask only for secrets or configuration that truly cannot be inferred; never ask the user to paste production secrets into source files or chat if a safer local configuration mechanism is possible.

# 4. Product identity and design direction

Product name: **BitLock**

Tagline: **Your files. Your keys. Your control.**

Create a polished, modern, trustworthy Android app. Use Jetpack Compose and Material 3 if the existing project permits it. The design should feel like a premium privacy/security tool rather than a generic file-manager clone.

Design direction:

- Clean layout, strong hierarchy, generous spacing, readable type, restrained use of color.
- Dark theme and light theme, following system preference by default.
- Dark theme may use deep navy/charcoal surfaces with restrained electric-blue/teal security accents. Keep accessible contrast.
- Show encryption and access states with text/icons, not color alone.
- Prefer concise labels, clear progress indicators, helpful empty states, and understandable errors.
- Avoid fake “hacker terminal” decoration, excessive glowing effects, scary red warnings for ordinary actions, and deceptive green “100% secure” badges.
- Add accessible content descriptions, minimum touch target sizing, and Compose previews where practical.
- Add a consistent app icon placeholder/vector if original brand assets are unavailable. Do not download or include unlicensed assets.

Suggested navigation:

- Home / Vault
- Protected Files
- Activity
- Settings

Core screens:

1. First-run welcome and security explanation.
2. Vault dashboard with protected file count and clear actions.
3. Import/select file flow using the Android Storage Access Framework (SAF).
4. Protect File setup with password/passphrase, confirmation, strength guidance, and a clear warning to store the password safely.
5. Encryption progress with cancel behavior that never leaves a final-looking corrupt container.
6. Protected file details: name/alias, size, type, created date, format version, verified integrity state when actually verified.
7. Unlock/decrypt flow.
8. Choose destination through SAF for decrypted output; default behavior must never overwrite the source silently.
9. Rename alias, organize, delete BitLock container, and safe confirmation flows.
10. Activity/audit screen for local events without storing secrets.
11. Settings for theme, lock timeout, biometric local unlock if properly implemented, screenshot security mode, and privacy information.
12. Useful empty states and error/retry screens.

# 5. Required technical foundation

Use the following defaults unless the existing repository or verified compatibility requires a reasoned alternative:

- Language: Kotlin.
- UI: Jetpack Compose + Material 3.
- Architecture: clear UI, domain, and data layers; MVVM or a similarly simple unidirectional-data-flow architecture.
- Async work: Kotlin coroutines and Flow/StateFlow.
- Navigation: a current stable Android navigation solution compatible with the project's Compose version.
- Dependency injection: Hilt or another established solution if it adds value; do not over-engineer a tiny MVP.
- Local metadata: Room, with the sensitive-field risks considered explicitly. Store only the metadata needed by the app. Protect sensitive metadata appropriately instead of assuming app-private storage alone is encryption.
- Preferences: DataStore for non-secret preferences only. Never store passwords or raw encryption keys in SharedPreferences/DataStore.
- File selection/export: Android Storage Access Framework (`ACTION_OPEN_DOCUMENT`, `ACTION_CREATE_DOCUMENT`, or appropriate modern APIs); do not request broad storage permissions without a clear need.
- Device key protection: Android Keystore for device-bound key material where appropriate; biometric authorization must use supported Android cryptographic APIs correctly.
- Cryptography: prefer Google Tink's maintained Android/Java cryptographic APIs for supported AEAD and Streaming AEAD use cases. Verify the dependency's current Android/API compatibility. Do not invent APIs or make unverified assumptions about Tink.
- Password KDF: use a reviewed, maintained Argon2id implementation if Android compatibility and maintenance are verified. If a safe Argon2id dependency cannot be verified, stop and document the choice; do not silently create a custom KDF. Use secure, unique random salts and versioned KDF parameters. Any fallback must be an established standard implemented through supported APIs and must be documented.
- Networking (future cloud phase): use HTTPS-only networking and an established HTTP client. Never disable certificate validation.
- Tests: local unit tests, instrumentation/UI tests where feasible, cryptographic known-answer/round-trip tests appropriate to chosen libraries, tampering tests, and large-file tests.

Do not use obsolete APIs or dependencies just because they are familiar. Verify the currently supported setup at implementation time.

# 6. Suggested modular package layout

Adapt to the repository rather than forcing a huge multi-module build. Keep boundaries clear. A possible package layout is:

```text
app/
  core/
    common/
    security/
    files/
    ui/
  data/
    local/
    repository/
  domain/
    model/
    usecase/
  feature/
    onboarding/
    vault/
    protect/
    unlock/
    filedetails/
    activity/
    settings/
  navigation/
```

Use small, named components with meaningful responsibilities. UI composables must not implement cryptography, access raw database APIs directly, or perform networking directly. Put work behind repositories/use cases and inject dependencies cleanly.

# 7. MVP scope — implement these features as real functionality

## 7.1 Local encrypted vault

- Import any file the system file picker can provide, subject to device/storage limits.
- Use a streaming input path from `ContentResolver` so very large files do not have to fit in memory.
- Let users protect a file with a strong passphrase. Include confirmation before starting encryption.
- Create a `.bitlock` encrypted container. Do not overwrite or delete the original file automatically. After successful verification, the user may explicitly choose to remove the original from a location they control, but explain that the app cannot guarantee forensic erasure from flash storage or cloud backups.
- Save vault containers in the app's private files directory by default. Never store plaintext content in the database, logs, caches or thumbnails.
- List protected files using an opaque internal ID plus safely stored/displayed metadata. If the original name is stored in the container, encrypt it. Avoid exposing original filenames in plaintext container headers when possible.
- Allow unlock/decrypt. Decrypted files should be streamed to a user-selected destination. A plaintext temporary file, if unavoidable, must be in a private cache directory, deleted in `finally` blocks, and never left behind after failure/cancellation. Document residual limitations.
- Before exporting plaintext, show a concise warning that exported plaintext is no longer protected by BitLock.
- Handle file picker cancellation, permission loss, zero-byte files, interrupted I/O, low storage, incorrect password, corrupted container, unsupported container version, and cancellation without crashing.
- Add progress, cancellation where safe, and retry flows. On cancel/failure, clean partial temporary/final output. Do not mark an incomplete container as protected.
- Provide a way to rename a display alias without rewriting decrypted file content.
- Deletion must use an explicit confirmation and must not claim secure forensic deletion.

## 7.2 File-type handling

Encryption/decryption must work for arbitrary bytes. The application must not alter the contents of PDF, Office documents, archives, media, or executable files during encryption.

For the first MVP, preview support should be limited to safe, realistic types such as images, plain text, and PDF only if a suitable maintained renderer/library is available. A lack of preview support must not prevent encrypting/decrypting any file. Do not execute, install, or automatically extract a protected executable/archive. Do not automatically extract archive contents.

DOCX/PPTX/XLSX/RAR/7Z viewing and controlled editing are future enhancements, not a reason to delay the secure encrypted-container MVP.

## 7.3 Vault lock and biometrics

- Add an app-level lock screen and configurable lock-on-background timeout.
- Offer biometric unlock as a convenience for reopening the local vault only when it is correctly implemented with Android's supported BiometricPrompt/Keystore flow.
- Do not use biometrics as a substitute for a portable password used to unlock a `.bitlock` container on another device.
- If biometric setup fails or the device does not support it, use the password flow. Do not lock the user out of a portable encrypted file merely because biometrics are unavailable.
- Never log or persist a password, derived key, cleartext keyset, token, or biometric data.

## 7.4 Share feature presentation

Create a coherent Sharing screen or feature entry, but do not fake a real internet share before the backend exists. In MVP, it may clearly state “Cloud sharing requires backend setup” and link to the implementation/configuration docs. If you build a local demo, label every result **DEMO ONLY — NOT A SECURE SHARE**.

Create a `SharingRepository`/service interface and policy models suitable for later implementation. Keep the local vault usable without an account or network connection.

# 8. Cryptographic/container design requirements

This is the highest-priority part of the MVP. Before implementing it, document the chosen construction and library APIs in `docs/SECURITY_MODEL.md`.

## 8.1 Keys and password handling

- Generate cryptographically secure random keys using a supported secure random API or the chosen crypto library's key-generation API.
- Use a fresh file-specific encryption key/keyset per protected file or version as appropriate. Do not reuse an encryption key across unrelated files without a documented, reviewed design.
- Passwords/passphrases must be processed by a reviewed password KDF with a unique random salt and appropriate versioned parameters. Passwords are not encryption keys by themselves.
- The derived key should wrap/protect the data-encryption key/keyset. Changing a password should ideally re-wrap the file key rather than require re-encrypting all payload bytes, if the chosen design supports this safely.
- Do not store passwords, derived keys, raw DEKs, or unwrapped Tink keysets at rest in ordinary files/database fields. Any unavoidable in-memory clear key material should have the shortest practical lifetime and references should be discarded promptly; acknowledge that reliable memory wiping is not guaranteed by managed runtimes.
- Ensure unique nonces/IVs wherever the chosen primitive requires them. Never reuse a nonce with the same key.
- Bind relevant container identifiers/version data as authenticated associated data where supported, to prevent swapping or tampering.
- Do not reveal detailed cryptographic internals in user-facing error messages. Keep diagnostics helpful but avoid secrets.

## 8.2 Streaming large files

- Prefer a maintained Streaming AEAD primitive such as Tink Streaming AEAD for large file contents when its use and key management work with the supported Android versions.
- Do not implement custom chunk encryption merely to claim “BitSeal” or bit-level locks.
- Streaming integrity must be validated according to the selected library's guarantees. If the streaming format cannot detect a property such as rollback/version substitution, do not claim that it does.
- Do not buffer the entire file in memory. Use bounded buffers/streams and test with files much larger than the expected buffer.
- Never leave an apparently valid container on disk if stream encryption failed midway.

## 8.3 `.bitlock` format

Create a versioned, documented binary container format. At minimum it must include a magic identifier and format version, plus only the minimum unencrypted fields required to identify and parse the format. Sensitive names, document titles, original path, owner email, and other sensitive attributes should be encrypted.

The encrypted content should contain an encrypted manifest/original metadata and the original raw file bytes in a design compatible with streaming encryption. The exact structure must follow the selected library and documented cryptographic construction rather than arbitrary custom cryptography.

The format must allow the app to:

- recognize a BitLock file;
- reject unsupported format versions safely;
- distinguish wrong password from a corrupted/modified container where the cryptographic API allows it without introducing an unsafe oracle;
- detect modified ciphertext and fail closed;
- include format/KDF/algorithm identifiers and versioned parameters as needed;
- evolve without silently breaking older files.

Write `docs/BITLOCK_CONTAINER_FORMAT.md` describing the finalized format, versioning, limitations, and migration strategy. Do not call a custom container “standardized.”

## 8.4 Tamper and corruption behavior

- Add tests that flip bytes in the header, encrypted payload, wrapped key material, and metadata; decryption should fail safely.
- Truncation and reordering should fail according to the chosen streaming primitive's guarantees.
- Ensure partial plaintext output is deleted if decryption or final authentication fails.
- Never respond to corruption by wiping source files or automatically deleting all keys.
- Give the user a calm, specific message such as “The password is incorrect or the protected file is damaged. No output file was saved.” Avoid falsely identifying an attack when ordinary corruption is equally plausible.

# 9. File processing and safety

- Use `ContentResolver` streams and Android SAF correctly. A URI is not a filesystem path; do not convert arbitrary URIs into guessed file paths.
- Use `use {}`/structured resource handling for all streams and descriptors.
- Validate free space when practical but still handle write failures correctly.
- Use a secure app-private temporary directory and restrictive file handling. Avoid world-readable/writable files.
- Do not use broad storage permissions unless a clearly justified requirement exists.
- Do not use shell commands, native code, archive extraction, or file execution to process user content unless specifically required and secured.
- Treat imported filenames, MIME types, file contents, and metadata as untrusted.
- Never render untrusted HTML or execute document macros/scripts.
- Do not generate previews for arbitrary files by launching external applications unless the user explicitly exports/opens a plaintext copy and acknowledges the security implications.

# 10. Temporary passwords and single-use access

Model credentials as access grants, not simply as long-lived passwords.

A future online share grant should support:

- creation timestamp;
- expiration timestamp;
- maximum successful activations/uses;
- usage counter;
- recipient binding where required;
- require login and/or OTP options;
- allowed operations (view/download/print/copy/edit/comment);
- maximum concurrent sessions;
- device restriction where technically supported;
- watermark requirement;
- revoked/consumed/expired state.

For an online one-use grant, the use counter must be consumed atomically by the authoritative backend so two simultaneous activation attempts cannot both succeed. A disabled/revoked/expired grant must be denied by the server, not merely hidden in the client UI.

For local-only credentials, clearly scope one-use enforcement to that installation/device state. Never claim it controls copies of a standalone file outside BitLock.

Generate high-entropy random credentials, store only a safe verifier/hash server-side where appropriate, rate-limit attempts, and avoid logging credentials. Do not rely on a six-digit code alone as the only protection for highly sensitive documents.

# 11. Future protected-sharing architecture (design now; ship only when real)

Prepare a clean future boundary for a web viewer and backend. Recommended future stack if appropriate:

- Supabase Auth for identity;
- PostgreSQL for metadata/policies;
- private object storage for ciphertext only in E2EE mode;
- Edge Functions or a dedicated API for privileged policy operations;
- row-level security (RLS) on every exposed table;
- server-side atomic functions/transactions for single-use grant consumption and revocation;
- short-lived sessions/leases and session renewal;
- a separate audit-event path with access controls;
- HTTPS-only APIs;
- rate limiting and abuse controls.

Never put a Supabase service-role/secret key inside the Android application. A public/publishable project key may exist in a client according to Supabase's documented model, but it does not replace RLS. Do not add placeholder keys that look real. Read configuration from safe local/build-time configuration and provide a `.env.example` or `local.properties.example` with dummy placeholders if needed. Ensure secrets/config files are ignored by Git.

If using Supabase, create reviewed SQL migrations and explicit RLS policies. Test both authorized and unauthorized access. Do not enable public bucket read access to “make uploads work.”

Required conceptual future tables may include:

- `profiles` (minimal user profile data);
- `organizations` and `organization_members`;
- `devices` (minimal device registration metadata);
- `files` and `file_versions`;
- `shares` and `share_recipients`;
- `share_grants` or `share_credentials`;
- `access_sessions`;
- `change_requests` and `comments`;
- `audit_events` and `revocations`.

Do not create every table immediately if no live backend feature uses it. Build only the schema needed by the current increment and keep migrations small.

## 11.1 Sharing mode distinction

Document two different future modes:

**E2EE / privacy-first mode:** plaintext and file decryption keys are not available to the server. Cloud stores ciphertext. A browser viewer may still expose plaintext to the recipient's browser while authorized, so browser/client compromise and copying remain threats.

**Enterprise-controlled mode:** an organization's controlled environment may render content or manage keys to support stronger administrative control. In this mode, the components that decrypt/render content may see plaintext. Do not describe it as server-blind E2EE.

Do not mix these models without an explicit, reviewed protocol and truthful UI copy.

## 11.2 Protected web viewer (later phase)

When implemented, the web viewer should:

- require recipient authorization before serving content/keys;
- never serve the original file from a public URL;
- enforce access policy on the server for every session/renewal;
- use opaque, high-entropy share identifiers;
- avoid putting secrets in query strings;
- use short-lived sessions and allow revocation;
- prevent indexing and avoid leaking protected data through analytics, referrers, browser logs, crash reporting or caching;
- use appropriate no-store/private caching headers, but do not claim headers eliminate copies;
- support dynamic watermarks where suitable;
- honestly describe screenshot/printing/copy restrictions as best-effort/platform-dependent controls.

# 12. Owner-controlled document workflow (future feature)

Design future domain models and repository boundaries for:

- read-only shared versions;
- recipient comments/annotations;
- change requests that do not mutate the owner's original file;
- owner approve/reject decisions;
- new versions created for approved changes;
- version history and audit records.

Never promise that a viewer can universally block text modification of an exported DOCX/PPTX/PDF. The reliable control is to avoid giving the recipient the editable original by default and show a controlled view instead. If download is allowed, the recipient can modify their downloaded copy; BitLock cannot prevent that external modification.

# 13. Screenshot, clipboard and viewer controls

- Apply Android `FLAG_SECURE` to high-sensitivity screens if appropriate and document its behavior/limitations.
- Android 14+ screenshot detection may be added when compatible, but it detects certain screenshot actions; it is not a universal screenshot-prevention system.
- Do not claim the app blocks cameras, rooted-device capture, all screen-recording tools, or all OEM/custom capture pathways.
- Do not add clipboard data at all for protected views unless explicitly allowed by a permission.
- Avoid storing decrypted preview images in persistent caches or backups.
- When switching to background, cover protected content immediately and apply the configured lock policy.
- Add tests or manual verification notes for secure-window behavior where instrumentation allows.

# 14. Local activity/audit records

Record useful local events, for example:

- `FILE_IMPORTED`;
- `FILE_PROTECTION_STARTED`;
- `FILE_PROTECTED`;
- `FILE_PROTECTION_FAILED`;
- `FILE_UNLOCK_SUCCEEDED`;
- `FILE_UNLOCK_FAILED`;
- `FILE_EXPORTED`;
- `FILE_DELETED`;
- `INTEGRITY_FAILURE`;
- `VAULT_LOCKED`;
- `VAULT_UNLOCKED`.

Audit rules:

- Never record passwords, passphrases, derived keys, raw DEKs, keysets, access tokens, or plaintext document contents.
- Do not imply that local events are tamper-proof. If the log is only on-device, describe it as a local activity history.
- Include timestamps and safe identifiers; avoid storing excessive personal data.
- If a later cloud audit log is introduced, use server-side authorization, appropriate retention, and tamper-evident/append-only storage where supported.

# 15. Data model and lifecycle

Implement sensible models such as:

- `VaultFile`: opaque ID, protected container location, created/updated times, file size, status, format version, optional display alias stored safely;
- `ProtectionJob`: progress, cancellation state and result;
- `UnlockResult`: success/failure type with no secret data;
- `LocalAuditEvent`: safe event type/time/opaque reference;
- `AccessPolicy` and `ShareGrant` as domain models for future sharing, independent from UI.

Use explicit states such as `PENDING`, `PROTECTING`, `PROTECTED`, `UNLOCKING`, `FAILED`, `CORRUPTED`, and `DELETED`, as appropriate. Do not represent active work only with a Boolean if the state machine requires more information.

Handle process death/restart so the list recovers correctly and incomplete jobs are not displayed as protected files. If an encryption job is interrupted, recover or safely remove partial outputs based on a documented policy.

# 16. Performance and reliability

- Never block the main thread with file or cryptographic work.
- Use Dispatchers.IO or an appropriate worker for blocking I/O and CPU work.
- For long-running work, consider WorkManager only if resumability/background execution is genuinely needed; don't add unnecessary complexity.
- Use bounded memory and close streams deterministically.
- Support large files as practical; do not promise unlimited file size.
- Maintain UI responsiveness and correct progress reporting.
- Support rotation/recreation and lifecycle changes.
- Avoid duplicate encryption from recomposition/double taps; protect actions from accidental repetition.
- Add tests for cancellation, no-storage-space errors where testable, invalid passwords, corruption, empty files, Unicode file names, and binary files containing arbitrary byte sequences.

# 17. Testing requirements

Create and run meaningful tests, not only compile checks.

## Unit tests

At minimum:

1. Encryption/decryption round-trip for zero-byte, small text, random binary, image/PDF-like bytes, Unicode-named files, and large generated streams.
2. Different encryption runs for the same plaintext produce different ciphertext where the primitive guarantees randomized encryption.
3. Incorrect password does not produce a usable plaintext output.
4. Mutating ciphertext, wrapped key data, or relevant container bytes fails safely.
5. Truncation/corruption never leaves a completed output file.
6. Unsupported versions fail closed.
7. File metadata parsing validates lengths and prevents allocation/overflow problems.
8. Cancellation cleans up partial files.
9. Filename/metadata handling cannot inject paths or write outside the intended app/destination location.
10. No secrets appear in `toString()`, app logs, exceptions surfaced to the user, or audit events.
11. Access-policy model tests for expiry/max-use/revocation semantics when that logic is implemented.

Use generated test data rather than checking real confidential files into the repository.

## Repository/build verification

- Run the available Gradle wrapper tasks, at minimum `test` and `assembleDebug` (adjust for actual project/modules).
- Run lint/static analysis tasks if configured and practical.
- Run instrumentation/UI tests if an emulator/device is available.
- Check `git diff` for unrelated deletions, generated secrets, accidental binaries, and debug-only behavior.
- Fix all build errors introduced by the implementation.
- If something cannot be run due to unavailable Android SDK/network/emulator, state the exact blocker and provide the command for the user to run. Never say tests passed when they were not run.

# 18. Privacy and permissions

- Request the minimum Android permissions possible.
- No contacts, location, microphone, camera, SMS, or unrelated permissions unless a future, explicit feature requires them.
- Explain why network access is needed if cloud features exist.
- Do not transmit filenames, contents, passwords, device identifiers or analytics by default.
- Do not add third-party analytics or crash-reporting tools without making their data implications explicit.
- Disable backup of sensitive local key material and decrypted content where appropriate in the app manifest/backup rules. Verify current Android backup rules and do not rely on an assumed default.
- Never place credentials or private files inside assets, resources, test fixtures, or Git history.

# 19. Error handling and UX language

Use plain language. Examples:

- “Choose a file to protect.”
- “Protection failed. Your original file has not been changed.”
- “The password is incorrect or the protected file is damaged. No output file was saved.”
- “The file was protected successfully.”
- “The exported file is a normal plaintext copy. BitLock can no longer control that copy.”
- “Cloud sharing is not configured yet.”
- “This access link has expired or been revoked.”

Never show messages such as “unhackable,” “100% protected,” “attacker destroyed,” or “secure deletion guaranteed.”

# 20. Documentation files to deliver

Create and maintain:

- `README.md`: what BitLock is, current implemented features, setup/run instructions, minimum Android requirements, tests, and current limitations.
- `docs/IMPLEMENTATION_PLAN.md`: phases, current status, next steps, and decisions.
- `docs/SECURITY_MODEL.md`: cryptographic algorithms/library choices, key hierarchy, password processing, nonce/IV handling, associated data, and key storage.
- `docs/THREAT_MODEL.md`: assets, trust boundaries, attackers, assumptions, mitigations, out-of-scope threats.
- `docs/KNOWN_LIMITATIONS.md`: honest limitations about screenshots, camera capture, copied plaintext, offline password guessing, rooted devices, revocation, flash storage, and backend status.
- `docs/BITLOCK_CONTAINER_FORMAT.md`: versioned format specification and forward-compatibility rules.
- `docs/TESTING.md`: test commands and manual security verification steps.
- Database migrations and backend setup docs only when backend integration is implemented.

# 21. Implementation milestones and order

Work through these milestones in order. After each milestone, run the relevant tests/build and summarize the result.

## Milestone 0 — Repository inspection and plan

Inspect repository, identify stack, write plan/security docs skeleton and report the detected project structure. Continue into the first implementation; don't stop after writing a plan.

## Milestone 1 — App shell and UI

Implement the Compose theme, navigation, vault dashboard, empty state, file import action, settings, progress/error components, and accessible UI. Use repositories/use cases instead of putting core logic in composables. Ensure the project builds.

## Milestone 2 — Cryptographic container engine

Implement a standalone, testable container/encryption service using a verified crypto library. Document the design first. Support streaming encrypt/decrypt, password-based key wrapping, versioned metadata, integrity verification, cancellation cleanup, and safe error results. Add extensive unit tests before wiring the UI.

If you cannot identify a sound supported design for portable password-protected key wrapping around the selected streaming primitive, do not invent one. Document the blocker and present the safest viable alternative for review.

## Milestone 3 — Vault integration

Connect the file picker, repository, Room metadata, background processing/progress, app-private encrypted container storage, file list/details, decryption to a SAF-selected destination, delete/rename flows, and local activity records. Verify local metadata does not expose secrets.

## Milestone 4 — Vault lock and biometrics

Add inactivity locking and biometric convenience only if the Keystore/BiometricPrompt integration is correct. Add lifecycle tests/manual verification notes.

## Milestone 5 — Local quality pass

Exercise failure cases, test large files, improve accessible UI, fix lint/build errors, document known limitations, and ensure the local vault works in airplane mode.

## Milestone 6 — Cloud-sharing groundwork

Only after the local vault is sound, document the backend architecture and create interface/types. If Supabase configuration is available and the user has authorized use of that project, implement a narrow, real feature with migrations, private storage, RLS, server-side grant consumption, revocation, tests, and setup docs. If configuration is absent, stop at a clear interface/configuration screen—do not mock security-sensitive operations.

## Milestone 7 — Final verification and handoff

Run all feasible tests/build commands. Inspect the diff. Report implemented features, tests actually run, failures/blockers, setup steps, security decisions, and unfinished work. Be direct about what is still a prototype and what has not undergone a professional security audit.

# 22. Coding standards

- Use idiomatic Kotlin, null safety, sealed result/error types, meaningful names and small functions.
- Do not place all code inside `MainActivity.kt`.
- Avoid giant files, giant composables and God classes.
- Keep UI state separate from durable entities and secret material.
- Use immutable UI state where practical.
- Handle lifecycle and coroutine cancellation correctly.
- Make data-layer APIs suspend/Flow where appropriate.
- Avoid swallowing exceptions. Map internal exceptions to safe domain errors while retaining useful, redacted debug information.
- Never log secret values or full user document metadata unnecessarily.
- Do not commit generated build output or downloaded dependencies.
- Add comments for non-obvious security decisions, not comments that merely restate code.
- If an existing architecture conflicts with these recommendations, adapt rather than performing an unnecessarily large rewrite.

# 23. Required final Codex response

At the end of the implementation session, provide a precise handoff with:

1. **What was implemented** — real features only.
2. **Key files created/changed** — short list with purpose.
3. **Security design** — selected primitives/library, key-wrapping scheme, file format, and relevant caveats.
4. **Build and tests** — exact commands run and pass/fail status; don't fabricate results.
5. **How to run** — Android Studio steps and any Gradle commands.
6. **Configuration still needed** — backend credentials, local SDK, emulator, signing, or other blockers, without exposing secrets.
7. **Known limitations** — especially that visible plaintext can be copied, remote revoke cannot recall exported plaintext, offline passwords can be attacked offline, and the app has not received an independent security audit.
8. **Next milestone** — the single most sensible next implementation step.

# 24. Begin now

Start by inspecting the repository and reporting its structure and current Android/build setup in your working notes. Create `docs/IMPLEMENTATION_PLAN.md` and a security/threat-model skeleton. Then implement Milestones 1 and 2 as far as safely possible, add tests, and connect the working cryptographic engine to the local vault. Do not stop at a project plan or attractive mockup. Make the app build and ensure that encryption/decryption is real. If a security-critical decision is unresolved, stop that specific feature rather than inventing crypto, clearly explain the blocker, and continue with other safe tasks.

**Definition of success:** a real Android app that can select an arbitrary file, protect it into a versioned `.bitlock` container using documented authenticated encryption and a password-derived wrapping key, store it in the local vault, detect wrong passwords/tampering, decrypt it back to a user-selected destination without altering the original, pass meaningful tests, and communicate its limitations honestly. Cloud shares, one-time online access, owner revocation, watermarked web viewing, enterprise RBAC, and document collaboration are subsequent milestones unless a real and secure backend is configured and tested.

---

## End of master prompt
