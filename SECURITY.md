# BitLock — security summary

Short version. The full models live in
[`docs/SECURITY_MODEL.md`](docs/SECURITY_MODEL.md) and
[`docs/THREAT_MODEL.md`](docs/THREAT_MODEL.md); if this file and
those disagree, those win and this file is the bug.

## Trust boundaries

- **This device** is where plaintext exists: files are encrypted
  locally with per-file random keys, wrapped by a key derived from
  the vault password (Argon2id → HKDF → KEK, in `bitlock_core`).
  Decryption for viewing happens in memory only.
- **The backend is untrusted for confidentiality.** It stores
  ciphertext only, plus the minimum share metadata. It never
  receives the vault password, plaintext file keys, or a share
  passcode in plaintext; share tokens are stored as hashes.
- **The server is trusted for access policy only**: it checks
  identity, expiry, revocation, and access limits on every share
  request, and counts redemptions atomically. A client-supplied
  "authorized" flag is never proof of anything.
- **Links are capabilities, not authorization.** Opening a
  `bitlock://share/...` link grants nothing by itself; redemption
  is decided server-side.
- **Imported files are untrusted bytes.** They are encrypted as
  opaque content; a name or MIME type is never treated as proof of
  content.

## Limitations (stated plainly)

- A forgotten vault password may mean the files cannot be
  recovered. There is no server-side copy of the keys.
- "View only" means BitLock provides no download/export action and
  controlled viewing blocks supported capture paths (FLAG_SECURE)
  with a watermark. It cannot stop an external camera, a rooted or
  otherwise compromised device, or someone re-typing what they see.
- Revoking or expiring a link stops future access through BitLock.
  It cannot take back a plaintext copy a recipient already
  exported.
- Exported files are ordinary plaintext files; BitLock does not
  protect them after export.
- A compromised device cannot be made trustworthy by this app.

## Reporting

This is a pre-release project; report issues to the repository
owner via the repository's issue tracker. Never include passwords,
keys, tokens, or file contents in a report.
