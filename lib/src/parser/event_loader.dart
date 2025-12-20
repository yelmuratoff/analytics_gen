import 'package:analytics_gen/src/util/logger.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';

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
///
/// Supports glob patterns for [eventsPath]:
/// - `events` - scans the `events` directory (non-recursive)
/// - `events/**/*.yaml` - recursively finds all YAML files
/// - `events/*.yaml` - finds YAML files in the top-level directory only
final class EventLoader {
  /// Creates a new event loader.
  EventLoader({
    required this.eventsPath,
    List<String> contextFiles = const [],
    List<String> sharedParameterFiles = const [],
    this.log = const NoOpLogger(),
    this.fs = const LocalFileSystem(),
  })  : _isGlob = _containsGlobChars(eventsPath),
        _contextFiles = {
          for (final path in contextFiles) path.replaceAll('\\', '/'),
        },
        _sharedParameterFiles = {
          for (final path in sharedParameterFiles) path.replaceAll('\\', '/'),
        };

  /// The path or glob pattern to find event files.
  final String eventsPath;

  /// Cached glob detection result.
  final bool _isGlob;

  /// Normalized context file paths for O(1) lookup.
  final Set<String> _contextFiles;

  /// Normalized shared parameter file paths for O(1) lookup.
  final Set<String> _sharedParameterFiles;

  /// The logger to use.
  final Logger log;

  /// The file system to use.
  final FileSystem fs;

  /// The list of context files to load.
  List<String> get contextFiles => _contextFiles.toList();

  /// The list of shared parameter files to ignore.
  List<String> get sharedParameterFiles => _sharedParameterFiles.toList();

  /// Returns true if [path] contains glob pattern characters.
  static bool _containsGlobChars(String path) {
    const chars = [0x2A, 0x3F, 0x5B, 0x7B]; // *, ?, [, {
    for (var i = 0; i < path.length; i++) {
      if (chars.contains(path.codeUnitAt(i))) return true;
    }
    return false;
  }

  /// Checks if a file should be excluded (context or shared parameter file).
  bool _shouldExclude(String normalizedPath) {
    // O(1) direct lookup
    if (_contextFiles.contains(normalizedPath) ||
        _sharedParameterFiles.contains(normalizedPath)) {
      return true;
    }
    // O(n) suffix check for relative paths
    for (final c in _contextFiles) {
      if (normalizedPath.endsWith('/$c')) return true;
    }
    for (final c in _sharedParameterFiles) {
      if (normalizedPath.endsWith('/$c')) return true;
    }
    return false;
  }

  /// Returns true if file has YAML extension.
  static bool _isYamlFile(String path) =>
      path.endsWith('.yaml') || path.endsWith('.yml');

  /// Loads all YAML files matching the configured [eventsPath].
  Future<List<AnalyticsSource>> loadEventFiles() async {
    return _isGlob ? _loadEventFilesWithGlob() : _loadEventFilesFromDirectory();
  }

  /// Loads event files using glob pattern matching.
  Future<List<AnalyticsSource>> _loadEventFilesWithGlob() async {
    List<File> yamlFiles;

    if (fs is LocalFileSystem) {
      yamlFiles = Glob(eventsPath)
          .listSync()
          .whereType<File>()
          .where((f) => _isYamlFile(f.path))
          .toList();
    } else {
      yamlFiles = await _listFilesMatchingPattern();
    }

    if (yamlFiles.isEmpty) {
      log.warning('No YAML files found matching pattern: $eventsPath');
      return const [];
    }

    yamlFiles.sort((a, b) => a.path.compareTo(b.path));

    log.info('Found ${yamlFiles.length} YAML file(s) matching $eventsPath');
    return _loadSourcesFromFiles(yamlFiles);
  }

  /// Loads event files from a directory (original behavior).
  Future<List<AnalyticsSource>> _loadEventFilesFromDirectory() async {
    final eventsDir = fs.directory(eventsPath);

    if (!eventsDir.existsSync()) {
      log.warning('Events directory not found at: $eventsPath');
      return const [];
    }

    final yamlFiles = eventsDir
        .listSync()
        .whereType<File>()
        .where((f) => _isYamlFile(f.path))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    if (yamlFiles.isEmpty) {
      log.warning('No YAML files found in: $eventsPath');
      return const [];
    }

    log.info('Found ${yamlFiles.length} YAML file(s) in $eventsPath');
    return _loadSourcesFromFiles(yamlFiles);
  }

  /// Loads sources from files in parallel, excluding context/shared files.
  Future<List<AnalyticsSource>> _loadSourcesFromFiles(List<File> files) async {
    final results = await Future.wait(
      files.map((file) async {
        final normalizedPath = file.path.replaceAll('\\', '/');
        if (_shouldExclude(normalizedPath)) return null;
        return AnalyticsSource(
          filePath: file.path,
          content: await file.readAsString(),
        );
      }),
    );
    return results.whereType<AnalyticsSource>().toList();
  }

  /// Lists files matching the glob pattern (for non-LocalFileSystem).
  Future<List<File>> _listFilesMatchingPattern() async {
    final normalizedPattern = eventsPath.replaceAll('\\', '/');
    final patternParts = normalizedPattern.split('/');
    final baseParts = <String>[];

    for (final part in patternParts) {
      if (_containsGlobChars(part)) break;
      baseParts.add(part);
    }

    if (baseParts.isEmpty) {
      log.warning('Glob pattern must have a base directory: $eventsPath');
      return const [];
    }

    final basePath = baseParts.join('/');
    final dir = fs.directory(basePath);
    if (!dir.existsSync()) {
      log.warning('Base directory not found: $basePath');
      return const [];
    }

    // Always collect recursively to ensure all potential matches are found
    final isRecursive = normalizedPattern.contains('**');
    final allFiles = <File>[];
    _collectFiles(dir, allFiles, recursive: isRecursive);

    final glob = Glob(normalizedPattern);
    return allFiles.where((file) {
      final filePath = file.path.replaceAll('\\', '/');
      if (!_isYamlFile(filePath)) return false;
      // Try matching both with and without leading slash
      return glob.matches(filePath) ||
          (filePath.startsWith('/') && glob.matches(filePath.substring(1)));
    }).toList();
  }

  /// Collects files from a directory synchronously.
  void _collectFiles(Directory dir, List<File> results,
      {required bool recursive}) {
    for (final entity in dir.listSync()) {
      switch (entity) {
        case File():
          results.add(entity);
        case Directory() when recursive:
          _collectFiles(entity, results, recursive: true);
      }
    }
  }

  /// Loads all configured context files in parallel.
  Future<List<AnalyticsSource>> loadContextFiles() async {
    final results = await Future.wait(
      _contextFiles.map((filePath) async {
        final file = fs.file(filePath);
        if (!file.existsSync()) {
          log.warning('Context file not found: $filePath');
          return null;
        }
        return AnalyticsSource(
          filePath: filePath,
          content: await file.readAsString(),
        );
      }),
    );
    return results.whereType<AnalyticsSource>().toList();
  }

  /// Loads a single source file.
  Future<AnalyticsSource?> loadSourceFile(String filePath) async {
    final file = fs.file(filePath);
    if (!file.existsSync()) {
      log.warning('File not found: $filePath');
      return null;
    }
    return AnalyticsSource(
      filePath: filePath,
      content: await file.readAsString(),
    );
  }
}
