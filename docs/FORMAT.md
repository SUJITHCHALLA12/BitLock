# `.bitlock` container format (version 1 target)

All integers are unsigned big-endian unless stated otherwise. This is the format target for Phase 1; the inherited pre-monorepo implementation has not yet been reconciled with encrypted metadata and is not certified as conforming.

## Header

| Field | Size | Meaning |
|---|---:|---|
| Magic | 4 bytes | ASCII `BLK1` |
| Version | 1 byte | `0x01` |
| JSON length | 4 bytes | UTF-8 JSON byte count, from 1 through 16 KiB |
| Header JSON | JSON length | UTF-8 object with the exact keys below |
| Header MAC | 16 bytes | First 16 bytes of HMAC-SHA256 over magic, version, length, and JSON |

Header JSON keys: `id` is base64 of a random 16-byte file ID; `s` is base64 of a random 16-byte Argon2id salt; `w` is base64 of the 60-byte wrapped DEK (`nonce[12] || ciphertext[32] || tag[16]`); `cs` is the chunk plaintext size (1 byte through 16 MiB); `pl` is the original file length; `kdf` is `{ "m": memoryKiB, "t": iterations, "p": parallelism }`. To bound unauthenticated resource use, accepted KDF parameters are 8 to 262,144 KiB memory (and at least `8*p` KiB), 1 to 10 iterations, and 1 to 16 parallelism. Original filename, MIME type, and creation time must not be put in plaintext header fields.

The Argon2id output is 32 bytes (default memory 65,536 KiB, 3 iterations, 2 lanes). HKDF-SHA256 derives separate 32-byte KEK and header-MAC keys using info labels `bitlock/kek` and `bitlock/header-mac`. AES-256-GCM wraps a fresh random 32-byte DEK under the KEK with AAD `ASCII("DEK") || fileId`. Verify the header MAC before DEK unwrapping or chunk processing.

## Encrypted records

The header is followed by one encrypted metadata record, then the file data chunks. Each record is `nonce[12] || ciphertext || tag[16]`. The metadata plaintext is UTF-8 JSON containing `filename`, `mimeType`, and `createdAt` (UTC ISO-8601); its plaintext is capped at 4 KiB, and its AAD is `ASCII("META") || fileId || headerMAC`. The metadata ciphertext length is inferred from the file length minus the header and expected data chunk lengths. No trailing bytes are allowed.

Data chunks use AES-256-GCM with a fresh random 12-byte nonce. Chunk AAD is `ASCII("CHUNK") || fileId || uint32(index) || byte(isLast) || headerMAC`. A zero-length file has exactly one empty data chunk. Otherwise count is `ceil(pl / cs)`, every non-final data chunk is `cs` bytes, and the final data chunk has the remainder (or `cs` when evenly divisible). A valid container has no bytes after its final data chunk.

The metadata record is additional to the `pl` data-byte chunk count. This rule resolves the requirement to encrypt descriptive metadata without including it in the plaintext file length; known-answer vectors must freeze the encoding before Phase 1 is accepted.
