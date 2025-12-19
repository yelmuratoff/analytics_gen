import 'package:analytics_gen/src/util/logger.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';

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
    List<String> contextFiles = const [],
    List<String> sharedParameterFiles = const [],
    this.log = const NoOpLogger(),
    this.fs = const LocalFileSystem(),
  })  : _contextFiles = contextFiles
            .map((p) => p.replaceAll('\\', '/'))
            .map((p) => p.endsWith('.yaml') || p.endsWith('.yml')
                ? p
                : p) // Keep extension
            .toSet(),
        _sharedParameterFiles =
            sharedParameterFiles.map((p) => p.replaceAll('\\', '/')).toSet();

  /// The path to the directory containing event files.
  final String eventsPath;

  /// The list of normalized context files to load.
  final Set<String> _contextFiles;

  /// The list of normalized shared parameter files to ignore.
  final Set<String> _sharedParameterFiles;

  /// The logger to use.
  final Logger log;

  /// The file system to use.
  final FileSystem fs;

  /// The list of context files to load.
  List<String> get contextFiles => _contextFiles.toList();

  /// The list of shared parameter files to ignore.
  List<String> get sharedParameterFiles => _sharedParameterFiles.toList();

  /// Loads all YAML files from the configured events directory.
  Future<List<AnalyticsSource>> loadEventFiles() async {
    final eventsDir = fs.directory(eventsPath);

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
      if (_contextFiles
          .any((c) => normalizedPath == c || normalizedPath.endsWith('/$c'))) {
        return null;
      }
      if (_sharedParameterFiles
          .any((c) => normalizedPath == c || normalizedPath.endsWith('/$c'))) {
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
      final file = fs.file(filePath);
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

  /// Loads a single source file.
  Future<AnalyticsSource?> loadSourceFile(String filePath) async {
    final file = fs.file(filePath);
    if (!file.existsSync()) {
      log.warning('File not found: $filePath');
      return null;
    }

    final content = await file.readAsString();
    return AnalyticsSource(
      filePath: filePath,
      content: content,
    );
  }
}
