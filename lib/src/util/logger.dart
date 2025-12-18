import 'package:meta/meta.dart';

import 'platform/platform.dart' as platform;

/// Log levels for the logger.
enum LogLevel {
  /// Debug level for detailed diagnostic information.
  debug,

  /// Info level for general informational messages.
  info,

  /// Warning level for potentially harmful situations.
  warning,

  /// Error level for error events.
  error,
}

/// Abstract logger interface.
/// Implementations can log messages at various levels.
abstract class Logger {
  /// Logs a debug message.
  void debug(String message);

  /// Logs an informational message.
  void info(String message);

  /// Logs a warning message.
  void warning(String message);

  /// Logs an error message with optional error and stack trace.
  void error(String message, [Object? error, StackTrace? stackTrace]);

  /// Creates a child logger with a prefix or context.
  Logger scoped(String label);
}

/// Console logger implementation that prints to standard output.
class ConsoleLogger implements Logger {
  /// Creates a new console logger.
  const ConsoleLogger({
    this.verbose = false,
    this.prefix = '',
  });

  /// Whether to enable verbose logging (debug level).
  final bool verbose;

  /// Optional prefix for log messages.
  final String prefix;

  @override
  void debug(String message) {
    if (verbose) {
      _print('DEBUG', message);
    }
  }

  @override
  void info(String message) {
    _print('INFO', message);
  }

  @override
  void warning(String message) {
    _print('WARN', message);
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _print('ERROR', message);
    if (error != null) {
      print(error);
    }
    if (stackTrace != null && verbose) {
      print(stackTrace);
    }
  }

  @override
  Logger scoped(String label) {
    return ConsoleLogger(
      verbose: verbose,
      prefix: prefix.isEmpty ? '[$label] ' : '$prefix[$label] ',
    );
  }

  void _print(String level, String message) {
    final p = prefix.isNotEmpty ? prefix : '';
    final supportsAnsi = platform.supportsAnsiEscapes;

    if (!supportsAnsi) {
      if (level == 'INFO') {
        print('$p$message');
      } else {
        print('[$level] $p$message');
      }
      return;
    }

    const reset = '\x1B[0m';
    const red = '\x1B[31m';
    const green = '\x1B[32m';
    const yellow = '\x1B[33m';
    const gray = '\x1B[90m';

    switch (level) {
      case 'DEBUG':
        print('$gray[DEBUG] $p$message$reset');
        break;
      case 'INFO':
        if (message.trim().startsWith('✓')) {
          print('$green$p$message$reset');
        } else {
          print('$p$message');
        }
        break;
      case 'WARN':
        print('$yellow[WARN] $p$message$reset');
        break;
      case 'ERROR':
        print('$red[ERROR] $p$message$reset');
        break;
      default:
        print('[$level] $p$message');
    }
  }

  /// Visible for testing: allows invoking `_print` with a custom level.
  @visibleForTesting
  void printForTest(String level, String message) => _print(level, message);
}

/// No-operation logger that ignores all log messages.
class NoOpLogger implements Logger {
  /// Creates a new no-op logger.
  const NoOpLogger();

  @override
  void debug(String message) {}

  @override
  void info(String message) {}

  @override
  void warning(String message) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  Logger scoped(String label) => this;
}
