enum LogLevel {
  debug,
  info,
  warning,
  error,
}

abstract class Logger {
  void debug(String message);
  void info(String message);
  void warning(String message);
  void error(String message, [Object? error, StackTrace? stackTrace]);

  /// Creates a child logger with a prefix or context.
  Logger scoped(String label);
}

class ConsoleLogger implements Logger {
  const ConsoleLogger({
    this.verbose = false,
    this.prefix = '',
  });

  final bool verbose;
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
    if (level == 'INFO') {
      print('$p$message');
    } else {
      print('[$level] $p$message');
    }
  }
}

class NoOpLogger implements Logger {
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
