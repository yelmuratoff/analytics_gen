import 'dart:io';

/// Represents a source file containing analytics definitions.
final class AnalyticsSource {
  /// The absolute path to the source file.
  final String filePath;

  /// The raw string content of the file.
  final String content;

  const AnalyticsSource({
    required this.filePath,
    required this.content,
  });
}

/// Handles discovery and loading of analytics definition files.
final class EventLoader {
  final String eventsPath;
  final List<String> contextFiles;
  final void Function(String message)? log;

  EventLoader({
    required this.eventsPath,
    this.contextFiles = const [],
    this.log,
  });

  /// Loads all YAML files from the configured events directory.
  Future<List<AnalyticsSource>> loadEventFiles() async {
    final eventsDir = Directory(eventsPath);

    if (!eventsDir.existsSync()) {
      log?.call('Events directory not found at: $eventsPath');
      return [];
    }

    final yamlFiles = eventsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml') || f.path.endsWith('.yml'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    if (yamlFiles.isEmpty) {
      log?.call('No YAML files found in: $eventsPath');
      return [];
    }

    log?.call('Found ${yamlFiles.length} YAML file(s) in $eventsPath');

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
        log?.call('Context file not found: $filePath');
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
