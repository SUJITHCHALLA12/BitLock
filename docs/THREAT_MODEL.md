# Threat model

This document describes intended protections. The Phase 0 repository does not yet implement the future app and cloud controls; each phase must update the model when it adds an attack surface.

## BitLock protects against

- stolen encrypted files
- unauthorized account access
- expired and revoked credentials
- modified ciphertext
- casual extraction
- unauthorized downloads
- normal copy/screenshot paths
- stolen share links after revocation
- database ciphertext exposure

## BitLock cannot guarantee protection against

- camera photographing the screen
- malware on a trusted device
- root-level compromise
- memory inspection after authorized decryption
- a user retyping visible content
- a user deliberately sharing plaintext
- screenshots outside supported platform capabilities
- already-exported plaintext

These are product goals, not claims that all controls exist today. Platform support and threat coverage must be verified before describing a control as active.

## Phase 1 attack surface and mitigations

The cryptographic core adds password guessing against stolen containers, malformed headers intended to consume resources, nonce/key misuse, container tampering, and plaintext temporary-file exposure. Argon2id raises password-guessing cost but cannot rescue a weak password; resource parameters are bounded before derivation; fresh CSPRNG values and per-file DEKs separate files; header and per-record authentication fail closed; decrypted output remains in a `.part` file until all records and EOF validate. App-private viewer lifecycle controls and platform capture controls are not implemented until Phase 2 and Phase 5.
