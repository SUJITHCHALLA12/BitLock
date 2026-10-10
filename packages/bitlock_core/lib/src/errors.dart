/// Raised when BitLock data is malformed or fails authentication.
class BitlockIntegrityException implements Exception {
  /// Creates an integrity error with a generic user-safe message.
  const BitlockIntegrityException(this.message);

  /// Explains that the container could not be authenticated or parsed.
  final String message;

  @override
  String toString() => 'BitlockIntegrityException: $message';
}

/// Integration seam for an app to record and surface an integrity failure.
///
/// The core passes no file name, password, key, or plaintext to this observer.
/// App and backend layers should bind the relevant file context privately.
abstract interface class BitlockIntegrityObserver {
  /// Records an integrity failure and schedules an owner notification if available.
  Future<void> onIntegrityFailure();
}
