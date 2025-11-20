import 'dart:io';

import 'package:analytics_gen/src/util/logger.dart';

/// Represents a source file containing analytics definitions.
final class AnalyticsSource {

  /// Creates a new analytics source.
  const AnalyticsSource({
    required this.filePath,
    required this.content,
  });
  /// The absolute path to the source file.
  final String filePath;

  /// The raw string content of the file.
  final String content;
}

/// Handles discovery and loading of analytics definition files.
final class EventLoader {

  /// Creates a new event loader.
  EventLoader({
    required this.eventsPath,
    this.contextFiles = const [],
    this.log = const NoOpLogger(),
  });
  /// The path to the directory containing event files.
  final String eventsPath;

  /// The list of context files to load.
  final List<String> contextFiles;

  /// The logger to use.
  final Logger log;

  /// Loads all YAML files from the configured events directory.
  Future<List<AnalyticsSource>> loadEventFiles() async {
    final eventsDir = Directory(eventsPath);

    if (!eventsDir.existsSync()) {
      log.warning('Events directory not found at: $eventsPath');
      return [];
    }

    final yamlFiles = eventsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml') || f.path.endsWith('.yml'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    if (yamlFiles.isEmpty) {
      log.warning('No YAML files found in: $eventsPath');
      return [];
    }

    log.info('Found ${yamlFiles.length} YAML file(s) in $eventsPath');

    final futures = yamlFiles.map((file) async {
      // Skip context files if they happen to be in the events directory
      // We normalize paths to ensure consistent comparison
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (contextFiles.any((c) => normalizedPath.endsWith(c))) {
        return null;
      }

      final content = await file.readAsString();
      return AnalyticsSource(
        filePath: file.path,
        content: content,
      );
    });

    return (await Future.wait(futures)).whereType<AnalyticsSource>().toList();
  }

  /// Loads all configured context files.
  Future<List<AnalyticsSource>> loadContextFiles() async {
    final sources = <AnalyticsSource>[];

    for (final filePath in contextFiles) {
      final file = File(filePath);
      if (!file.existsSync()) {
        log.warning('Context file not found: $filePath');
        continue;
      }

      final content = await file.readAsString();
      sources.add(AnalyticsSource(
        filePath: filePath,
        content: content,
      ));
    }

    return sources;
  }
}
