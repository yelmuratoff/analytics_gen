import 'package:analytics_gen/src/util/logger.dart';

class TestLogger implements Logger {
  final List<String> logs;

  TestLogger(this.logs);

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
