import 'dart:async';

import 'package:analytics_gen/src/util/logger.dart';

/// Thrown by [exitForTest] where a CLI runner would end the process.
final class TestExit implements Exception {
  const TestExit(this.code);

  final int code;

  @override
  String toString() => 'TestExit($code)';
}

Never exitForTest(int code) => throw TestExit(code);

/// Runs a CLI [command] that ends the process through [exitForTest].
///
/// Returns everything it printed, joined by newlines, and the exit code it
/// passed to [exitForTest], or null when it returned normally.
Future<({String output, int? exitCode})> runCliForTest(
  Future<void> Function() command,
) async {
  final printed = <String>[];
  int? exitCode;
  await runZoned(
    () async {
      try {
        await command();
      } on TestExit catch (e) {
        exitCode = e.code;
      }
    },
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, line) => printed.add(line),
    ),
  );
  return (output: printed.join('\n'), exitCode: exitCode);
}

class TestLogger implements Logger {
  TestLogger(this.logs);
  final List<String> logs;

  @override
  void debug(String message) => logs.add(message);

  @override
  void info(String message) => logs.add(message);

  @override
  void warning(String message) => logs.add(message);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    logs.add(message);
    if (error != null) logs.add(error.toString());
  }

  @override
  Logger scoped(String label) => this;
}
