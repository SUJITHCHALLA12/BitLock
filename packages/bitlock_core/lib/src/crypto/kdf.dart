import 'dart:convert';
import 'dart:isolate';

import 'package:cryptography/cryptography.dart';

/// Hard upper bounds applied before KDF work on untrusted container values.
abstract final class KdfLimits {
  /// Maximum accepted Argon2id memory size, in KiB (256 MiB).
  static const maxMemoryKiB = 256 * 1024;
  /// Maximum accepted Argon2id iteration count.
  static const maxIterations = 10;
  /// Maximum accepted Argon2id parallelism.
  static const maxParallelism = 16;
}

/// Argon2id settings stored in each BitLock file.
class KdfParams {
  /// Creates Argon2id settings, defaulting to 64 MiB, 3 iterations and 2 lanes.
  const KdfParams({this.memoryKiB = 65536, this.iterations = 3, this.parallelism = 2});

  /// Amount of Argon2id memory in KiB.
  final int memoryKiB;

  /// Number of Argon2id iterations.
  final int iterations;

  /// Argon2id parallelism.
  final int parallelism;

  /// Encodes these parameters using the compact container keys.
  Map<String, Object> toJson() => {'m': memoryKiB, 't': iterations, 'p': parallelism};

  /// Decodes parameters and rejects invalid values.
  factory KdfParams.fromJson(Object? value) {
    if (value is! Map<String, dynamic> || value.length != 3 ||
        !value.keys.toSet().containsAll({'m', 't', 'p'})) {
      throw const FormatException('Invalid KDF parameters');
    }
    final m = value['m'];
    final t = value['t'];
    final p = value['p'];
    if (m is! int || t is! int || p is! int || m < 8 || m > KdfLimits.maxMemoryKiB ||
        t < 1 || t > KdfLimits.maxIterations || p < 1 || p > KdfLimits.maxParallelism || m < 8 * p) {
      throw const FormatException('Invalid KDF parameters');
    }
    return KdfParams(memoryKiB: m, iterations: t, parallelism: p);
  }
}

/// Holds the independently derived keys used for DEK wrapping and header MAC.
class DerivedKeys {
  /// Creates the two key values.
  const DerivedKeys({required this.kek, required this.headerMacKey});

  /// Key-encryption key used to wrap the file DEK.
  final SecretKey kek;

  /// Key used to authenticate the container header.
  final SecretKey headerMacKey;
}

/// Runs Argon2id away from the calling isolate, then derives two HKDF keys.
Future<DerivedKeys> deriveKeys(String password, List<int> salt, KdfParams params) async {
  if (salt.length != 16) throw ArgumentError.value(salt.length, 'salt.length');
  if (params.memoryKiB < 8 || params.memoryKiB > KdfLimits.maxMemoryKiB ||
      params.iterations < 1 || params.iterations > KdfLimits.maxIterations ||
      params.parallelism < 1 || params.parallelism > KdfLimits.maxParallelism ||
      params.memoryKiB < 8 * params.parallelism) {
    throw ArgumentError.value(params, 'params');
  }
  // SecretKey.extractBytes() may return a read-only view. Copy it into a
  // caller-owned buffer so the finally block can clear that buffer reliably.
  final argonOutput = (await Isolate.run(() async {
    final algorithm = Argon2id(
      memory: params.memoryKiB,
      iterations: params.iterations,
      parallelism: params.parallelism,
      hashLength: 32,
    );
    final passwordBytes = utf8.encode(password);
    try {
      return await (await algorithm.deriveKey(
        secretKey: SecretKey(passwordBytes),
        nonce: salt,
      )).extractBytes();
    } finally {
      passwordBytes.fillRange(0, passwordBytes.length, 0);
    }
  })).toList();
  try {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final root = SecretKey(argonOutput);
    final kek = await hkdf.deriveKey(secretKey: root, info: utf8.encode('bitlock/kek'));
    final mac = await hkdf.deriveKey(secretKey: root, info: utf8.encode('bitlock/header-mac'));
    return DerivedKeys(kek: kek, headerMacKey: mac);
  } finally {
    argonOutput.fillRange(0, argonOutput.length, 0);
  }
}
