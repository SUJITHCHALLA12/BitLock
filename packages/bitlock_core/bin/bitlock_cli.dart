import 'dart:io';

import 'package:bitlock_core/bitlock_core.dart';

Future<String?> _readPassword(String prompt) async {
  stdout.write(prompt);
  var previousEcho = true;
  var changedEcho = false;
  try {
    previousEcho = stdin.echoMode;
    stdin.echoMode = false;
    changedEcho = true;
  } on Object {
    // Piped stdin has no terminal echo setting.
  }
  try {
    final value = stdin.readLineSync();
    return value;
  } finally {
    if (changedEcho) {
      try { stdin.echoMode = previousEcho; } on Object { /* Terminal may have closed. */ }
      stdout.writeln();
    }
  }
}

Future<void> main(List<String> args) async {
  if (args.length != 3 || !{'encrypt', 'decrypt'}.contains(args.first)) {
    stderr.writeln('Usage: dart run bin/bitlock.dart encrypt <input> <output.bitlock>');
    stderr.writeln('   or: dart run bin/bitlock.dart decrypt <input.bitlock> <output>');
    exitCode = 2;
    return;
  }
  final operation = args[0];
  final input = File(args[1]);
  final output = File(args[2]);
  if (!await input.exists()) { stderr.writeln('Input file does not exist.'); exitCode = 1; return; }
  if (await output.exists() || await File('${args[2]}.part').exists()) {
    stderr.writeln('Output file already exists.'); exitCode = 1; return;
  }
  try {
    final password = await _readPassword('Password: ');
    if (password == null) { stderr.writeln('Could not read password.'); exitCode = 1; return; }
    if (operation == 'encrypt') {
      final confirmation = await _readPassword('Confirm password: ');
      if (password != confirmation) { stderr.writeln('Passwords do not match.'); exitCode = 1; return; }
      await encryptFile(args[1], args[2], password);
    } else {
      await decryptFile(args[1], args[2], password);
    }
    stdout.writeln('Success.');
  } on BitlockIntegrityException {
    stderr.writeln('Decryption failed: invalid password or damaged file.');
    exitCode = 3;
  } on FileSystemException catch (error) {
    stderr.writeln('I/O error: ${error.message}');
    exitCode = 1;
  } on Object {
    stderr.writeln('Operation failed.');
    exitCode = operation == 'decrypt' ? 3 : 1;
  }
}
