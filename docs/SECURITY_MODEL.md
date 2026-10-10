# Security model

BitLock defaults to end-to-end encryption (E2EE): a client encrypts file contents and the server stores ciphertext, metadata needed to route and authorize objects, and wrapped keys. In E2EE mode, the server does not receive plaintext file keys or plaintext file contents. Managed key handling and server-side rendering are out of scope until Phase 7 and require explicit organization selection.

Authorization is not encryption, and encryption is not authorization. You need both. Encryption limits what a storage provider can learn from file contents; authorization decides who may obtain a ciphertext or a usable wrapped key. Revocation can stop future access checks and renewals, but cannot retract plaintext already viewed or exported.

Password-derived keys use Argon2id followed by HKDF with distinct labels for key wrapping and header authentication. A random per-file data encryption key (DEK) encrypts content; a key-encryption key (KEK) wraps the DEK. The server must never store passwords, recovery keys, unwrapped DEKs, or MAC keys.

Memory clearing is best effort. Dart lists can be overwritten when owned by the caller, but garbage collection, immutable strings, package internals, copies made by cryptographic APIs, operating system paging, and crash dumps prevent a reliable guarantee that every key copy is erased immediately. Plaintext temporary files must be app-private, excluded from backups, and cleaned when the viewer closes, the app backgrounds, and at next launch.

The Phase 1 core overwrites its owned password-byte, DEK, and plaintext chunk buffers after their last use where control flow permits. SecretKey instances and buffers allocated internally by `cryptography`, the isolate runtime, and the Dart VM are opaque and cannot be reliably zeroized by this package. This is a best-effort reduction of lifetime, not guaranteed erasure.

The core exposes an optional integrity observer interface so an app integration can bind an integrity failure to a private audit event and owner notification. The standalone CLI has no owner account or audit service, so it reports the generic failure locally. The observer receives no path, password, key, or plaintext from the core.

Use honest language: controlled viewing, copy-resistant, and blocks supported capture paths. Never promise that content cannot be copied or screenshotted.
