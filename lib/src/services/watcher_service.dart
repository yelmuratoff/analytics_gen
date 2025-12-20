import 'dart:io';

import 'package:analytics_gen/src/cli/watch_scheduler.dart';
import 'package:analytics_gen/src/util/banner_printer.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:path/path.dart' as path;

/// Service to watch for file changes and trigger regeneration.
class WatcherService {
  /// Default constructor
  const WatcherService({
    required this.projectRoot,
    required this.logger,
  });

  /// Project root directory.
  final String projectRoot;

  /// Logger instance.
  final Logger logger;

  /// Watches for changes in [eventsPath] and triggers [onGenerate].
  Future<void> watch({
    required String eventsPath,
    required Future<void> Function() onGenerate,
  }) async {
    printBanner('Analytics Gen - Watch Mode', logger: logger);
    logger.info('');
    logger.info('Watching for changes in: $eventsPath');
    logger.info('Press Ctrl+C to stop');
    logger.info('');

    // Initial run
    await onGenerate();

    final eventsDir = Directory(path.join(projectRoot, eventsPath));
    if (!eventsDir.existsSync()) {
      // Throwing instead of exit(1) to be library-friendly
      throw FileSystemException(
          'Events directory does not exist', eventsDir.path);
    }

    final scheduler = WatchRegenerationScheduler(
      onGenerate: () async {
        logger.info('');
        logger.info('Regenerating...');
        logger.info('');
        await onGenerate();
      },
    );

    try {
      await for (final event in eventsDir.watch(recursive: true)) {
        if (event.path.endsWith('.yaml') || event.path.endsWith('.yml')) {
          logger.info('');
          logger.info('Change detected: ${path.basename(event.path)}');
          scheduler.schedule();
        }
      }
    } finally {
      scheduler.dispose();
    }
  }
}
