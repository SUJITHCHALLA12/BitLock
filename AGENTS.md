# Repository Guidelines

## Project Structure & Module Organization

- `packages/bitlock_core/` contains the pure Dart encryption/container library, CLI (`bin/`), and unit tests (`test/`).
- `app/` contains the Flutter Android app (`lib/`), widget tests (`test/`), and integration tests (`integration_test/`).
- `backend/supabase/` reserves directories for migrations, policies, functions, and seed data.
- `docs/` holds security and threat models, format and architecture decisions, release plans, and phase reports. `scripts/check_secrets.sh` checks for committed secrets.

## Build, Test, and Development Commands

Run commands from the indicated package directory:

- Core: `cd packages/bitlock_core; dart pub get; dart analyze; dart test`
- App: `cd app; flutter pub get; flutter analyze; flutter test`
- CLI: from `packages/bitlock_core`, run `dart run bin/bitlock_cli.dart encrypt <input> <output.bitlock>` or `dart run bin/bitlock_cli.dart decrypt <input.bitlock> <output>`.
- Secret scan: `bash scripts/check_secrets.sh` from the repository root.

CI excludes slow core tests on push and pull requests; run `dart test --tags slow` in the core package for the scheduled large-file suite.

## Coding Style & Naming Conventions

Follow `.editorconfig`: UTF-8, LF endings, two spaces, and a final newline. Use Dart and Flutter analyzer rules in each package’s `analysis_options.yaml`. Name Dart files in `snake_case.dart`, types in `UpperCamelCase`, and members/variables in `lowerCamelCase`. Keep the core independent of Flutter. Update relevant architecture or security documentation when changing format, cryptography, or trust boundaries.

## Testing Guidelines

Use the Dart `test` package for core tests and `flutter_test` for app tests. Put core tests under `packages/bitlock_core/test/` and app tests under `app/test/`; use descriptive `*_test.dart` names. Add or update tests for behavior changes, especially format compatibility and cryptographic vectors. Run analysis and the relevant test command before submitting.

## Commit & Pull Request Guidelines

There is no commit history yet to establish a project-specific convention. Use concise imperative subjects, optionally with a scope, such as `core: validate container header`. Pull requests should describe the change and motivation, link related issues, list validation commands and results, and include screenshots for visible app changes. Call out security or format implications and update the corresponding docs.

## Security & Configuration

Never commit credentials, keys, or plaintext test data containing secrets. Run the secret scan before submitting. Treat the threat model and security model as requirements: default cloud storage is ciphertext-only, and any change to key handling or data exposure needs explicit documentation.


## instructions

# AGENTS.md — BitLock working agreement

This file is the contract for every AI agent (and human) working in this
repository. Read it fully before changing anything. When this file and a
prompt disagree, stop and ask; do not silently pick one.

---

## 1. What we are building

BitLock is a zero-trust file protection platform:
- `packages/bitlock_core`: pure Dart crypto, container format, policy
  evaluation, audit hash chain, versioning. No Flutter imports.
- `app/`: Flutter Android app (vault, viewer, sharing, lock management).
- `backend/supabase/`: schema, RLS, storage, edge functions.
- `admin/`, `web_viewer/`: Next.js, Phase 7 only.

The authoritative scope is `docs/PHASE_REPORTS/` plus the phase specification
in the project brief. Do not build beyond the current phase.

---

## 2. Operating principles (read these first)

1. **Understand before editing.** Read the existing code, tests, and docs for
   the area you will touch. Search for callers (`grep -rn`) before changing a
   function signature. Never assume a file's contents from memory.
2. **Extend, don't replace.** If code already exists from another agent or
   from an earlier phase, your default is to build on it. Rewriting working
   code requires a written justification in the phase report: what is wrong,
   what test proves it, and what behavior is preserved.
3. **Verify, don't assume.** A claim that something works is only valid if
   you ran the command that proves it and read its output. Do not write
   "tests pass" without pasting the summary line.
4. **Think twice before destructive actions.** Before deleting, overwriting,
   or renaming a file, `git diff` it and confirm no other code depends on it.
5. **Small, reviewable steps.** One logical change per commit. Commit message
   format: `<area>: <what and why>` (e.g. `core/format: reject jsonLen > 16 KiB`).
6. **Say what you don't know.** If a spec point is ambiguous, unverified, or
   depends on an external service you cannot reach, write it in the phase
   report under "Open questions" instead of guessing.

---

## 3. Before you write any code (mandatory checklist)

Run these and read the output before starting:

```bash
git status                       # clean tree? if not, understand why first
git log --oneline -20            # what has been done, by whom
ls docs/PHASE_REPORTS/           # current phase and prior reports
cat docs/DECISIONS.md            # open decisions and defaults
cat docs/FORMAT.md               # container spec (source of truth for bytes)
dart --version && flutter --version
```

Then write `docs/PHASE_REPORTS/phase-N-plan.md` with:
- files you will create or modify (list existing files you will *extend*),
- tests you will write, including negative tests,
- acceptance commands you will run,
- risks and open questions.

Do not write production code until the plan exists.

---

## 4. Hard rules (violations block merge)

### Cryptography
- Use only the `cryptography` package primitives: AES-256-GCM, HKDF-SHA256,
  HMAC-SHA256, Argon2id, Ed25519. Never write a cipher, mode, KDF, MAC, or
  padding scheme. Never "improve" a primitive.
- Every encrypted chunk is AEAD. Every unencrypted structure that matters is
  covered by a MAC or signature.
- Randomness only from `Random.secure()` (or the package's CSPRNG). Never
  `Random()` for keys, nonces, salts, IDs, or tokens.
- Nonces are never reused under the same key. Fresh 12-byte random nonce per
  AES-GCM operation.
- Compare MACs and tokens in constant time.
- Passwords are never used directly as keys: Argon2id -> HKDF -> KEK -> wraps DEK.

### Secrets
- No password, key, token, or plaintext content in: logs, `print`, exceptions
  messages, crash reports, URLs, query strings, analytics, filenames, or
  database rows (except wrapped/hashed forms defined in the spec).
- Share tokens and access codes are stored only as SHA-256 or Argon2id hashes.
- Never commit secrets. `.env` files are git-ignored. CI greps for patterns
  (see §7).

### Failure behavior
- Tampering, wrong password, failed MAC, failed AEAD, or truncation throws
  `BitlockIntegrityException` with a generic message and never emits partial
  plaintext.
- On failure, delete `<out>.part` and leave no output at the final path.
- **Never** implement self-destruct, data wiping, or any action that destroys
  ciphertext in response to tampering or failed logins. Fail closed, alert,
  and keep the ciphertext intact.

### Honest claims
- Do not write "unhackable", "impossible to copy", "screenshot-proof", or
  "guaranteed secure" anywhere: code comments, UI strings, docs, or commit
  messages. Use "controlled viewing", "blocks supported capture paths",
  "copy-resistant".
- Any UI status ("Protected", "Integrity verified", "Secure hardware") must
  be backed by a real check in code, with a test.

### Scope
- Do not add UI, Flutter, network, or Android code to `bitlock_core`.
- Do not change the container format without updating `docs/FORMAT.md`,
  the known-answer vectors in `test/vectors/`, and the tests in the same commit.
- Do not add dependencies without recording them in `docs/DEPENDENCIES.md`
  (purpose, license, last release date, why not an existing dependency).

---

## 5. Working with existing code (anti-overwrite protocol)

When you find code you did not write in this session:

1. **Read it completely**, including its tests.
2. **Run its tests** before changing anything. Record the baseline result.
3. **Identify the contract**: what inputs, outputs, errors, and invariants it
   guarantees. Write these down in your plan.
4. **Make the smallest change** that meets the spec. Extend with new functions
   or new files where possible.
5. **Preserve every existing test.** If a test must change, explain in the
   commit message why the old expectation was wrong, with evidence.
6. **Compare before and after**: run the full suite and the known-answer
   vectors. Any change to a vector means a format change: stop and ask.

Forbidden without explicit approval in the phase plan:
- deleting files other agents created,
- replacing a module wholesale when a targeted edit would do,
- reformatting unrelated code (keep diffs minimal),
- "cleaning up" code outside the task.

---

## 6. Cross-checking your work (do this every time)

Before declaring a change done, answer these in the phase report:

1. **Does it compile and analyze?** `dart analyze` / `flutter analyze` with
   zero errors and zero warnings.
2. **Do all tests pass?** Paste the summary line (e.g. `+142: All tests passed!`).
3. **Is the negative case tested?** For every security function, is there a
   test where it must fail? Show it.
4. **Did I break a caller?** `grep -rn` for the function you changed; confirm
   each caller still compiles and is tested.
5. **Does it match the spec?** Compare against `docs/FORMAT.md` and the phase
   spec line by line for anything touching bytes, keys, or policy.
6. **Could an attacker exploit a boundary?** Check: length fields (overflow,
   negative, zero), off-by-one on chunk boundaries, reordering, truncation,
   duplicate input, concurrent access, time-of-check vs time-of-use.
7. **Is plaintext contained?** Confirm no plaintext reaches a log, cache
   without cleanup, backup, or external storage.
8. **Independent re-check.** Ask a second pass (a fresh agent session or a
   human reviewer) to review the diff against this file. Record who did it.

If any answer is "not sure," the work is not done. Write the uncertainty
down and resolve it with a test or a question.

---

## 7. Verification commands

Run from the repo root. All must pass before a phase gate.

```bash
# core
(cd packages/bitlock_core && dart pub get && dart analyze && dart test)

# known-answer vectors must not change silently
(cd packages/bitlock_core && dart test test/vectors_test.dart)

# app (once it exists)
(cd app && flutter pub get && flutter analyze && flutter test)

# secret scan (must print nothing)
git grep -nE "(password|secret|api[_-]?key|token)\s*=\s*['\"][^'\"]{6,}['\"]" -- ':!*.md' || echo "clean"

# CLI round trip (Phase 1+)
head -c 3145728 /dev/urandom > /tmp/s.bin
printf 'pw\npw\n' | dart run packages/bitlock_core/bin/bitlock_cli.dart encrypt /tmp/s.bin /tmp/s.bitlock
printf 'pw\n' | dart run packages/bitlock_core/bin/bitlock_cli.dart decrypt /tmp/s.bitlock /tmp/s.out
cmp /tmp/s.bin /tmp/s.out && echo "round trip OK"
```

Tampering check: flip one byte of `/tmp/s.bitlock` and confirm decrypt exits
with code 3 and `/tmp/s.out` does not exist.

---

## 8. Phase gates

- Work one phase at a time, in order: 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7.
- Do not start phase N+1 until `docs/PHASE_REPORTS/phase-N-report.md` exists
  and every acceptance check in it shows a real result.
- A blocked check (for example, no Supabase credentials or no Android device)
  is recorded as BLOCKED with the exact command or setup needed. It is not
  marked as passed.
- Each report lists: what was built, test counts, verification output,
  deviations from spec with reasons, known gaps, open questions.

---

## 9. Multi-agent coordination

When more than one agent works in the repository:
- Claim a task by adding a line to `docs/PHASE_REPORTS/claims.md`:
  `<agent name> | <area> | <started date>`. Release it when finished.
- Do not edit files claimed by another agent without reading their open
  commits and asking in `claims.md`.
- Before pushing, `git pull --rebase`, rerun the verification commands, and
  resolve conflicts by reading both sides. Never resolve a conflict in
  security code by taking one side blindly.
- If another agent's change breaks your tests, fix the root cause, or report
  it in `claims.md`. Do not delete their tests to make yours pass.

---

## 10. Stop-and-ask triggers

Stop, write the question in the phase report, and wait for a human when:
- a spec requirement conflicts with another requirement,
- a change would alter the container format or a known-answer vector,
- a test that previously passed now fails and you cannot find the root cause
  within a reasonable effort,
- a dependency has a license or security concern,
- a step requires credentials, a device, or an external account,
- you are tempted to skip a test, weaken an assertion, or add `// ignore:`
  to silence the analyzer.

---

## 11. Definition of done

A task is done only when:
- the code compiles and analyzes clean,
- positive and negative tests exist and pass,
- verification commands were run and their output recorded,
- docs (FORMAT.md, THREAT_MODEL.md, DECISIONS.md) match the code,
- the independent cross-check in §6 was performed and recorded,
- the commit history is readable and each commit builds.

"It should work" is not done.