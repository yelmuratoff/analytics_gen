import 'package:file/file.dart';
import 'package:file/local.dart';

/// Manages file output operations for the code generator.
///
/// Handles directory creation, file writing, and cleaning up stale files.
/// Abstracting this allows for unit testing via [MemoryFileSystem].
class OutputManager {
  /// Creates a new output manager.
  const OutputManager({
    this.fs = const LocalFileSystem(),
  });

  /// The file system to use.
  final FileSystem fs;

  /// Ensures that all necessary output directories exist.
  Future<void> prepareOutputDirectories(
    String outputDir,
    String eventsDir,
    String contextsDir,
  ) async {
    final outputDirectory = fs.directory(outputDir);
    if (!outputDirectory.existsSync()) {
      await outputDirectory.create(recursive: true);
    }

    final eventsDirectory = fs.directory(eventsDir);
    if (!eventsDirectory.existsSync()) {
      await eventsDirectory.create(recursive: true);
    }

    final contextsDirectory = fs.directory(contextsDir);
    if (!contextsDirectory.existsSync()) {
      await contextsDirectory.create(recursive: true);
    }
  }

  /// Removes stale files from the events directory.
  ///
  /// [generatedFiles] is a set of absolute file paths that were generated
  /// in the current run. Any other files in [eventsDir] will be deleted.
  Future<void> cleanStaleFiles(
    String eventsDir,
    Set<String> generatedFiles,
  ) async {
    final dir = fs.directory(eventsDir);
    if (!dir.existsSync()) return;

    await for (final entity in dir.list()) {
      if (entity is File && !generatedFiles.contains(entity.path)) {
        await entity.delete();
      }
    }
  }

  /// Writes content to a file only if it has changed.
  Future<void> writeFileIfContentChanged(
      String filePath, String content) async {
    final file = fs.file(filePath);
    if (file.existsSync()) {
      final existingContent = await file.readAsString();
      if (existingContent == content) {
        return;
      }
    } else {
      await _createParentDirs(file);
    }

    await file.writeAsString(content);
  }

  Future<void> _createParentDirs(File file) async {
    final parent = file.parent;
    if (!parent.existsSync()) {
      await parent.create(recursive: true);
    }
  }
}
