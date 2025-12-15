import 'package:file/file.dart';
import 'package:file/memory.dart';

import 'package:analytics_gen/src/parser/event_loader.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:test/test.dart';

class TestLogger implements Logger {
  final messages = <String>[];

  @override
  void debug(String message) => messages.add('DEBUG: $message');

  @override
  void info(String message) => messages.add('INFO: $message');

  @override
  void warning(String message) => messages.add('WARNING: $message');

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      messages.add('ERROR: $message');

  @override
  Logger scoped(String label) => TestLogger();
}

void main() {
  group('EventLoader', () {
    late Directory tempDir;
    late String eventsPath;
    late TestLogger logger;

    late FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
      tempDir = fs.systemTempDirectory.createTempSync('event_loader_test_');
      eventsPath = tempDir.path;
      logger = TestLogger();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('loadContextFiles logs warning for missing context files', () async {
      final loader = EventLoader(
        fs: fs,
        eventsPath: eventsPath,
        contextFiles: ['nonexistent_context.yaml', 'another_missing.json'],
        log: logger,
      );

      final sources = await loader.loadContextFiles();

      expect(sources, isEmpty);
      expect(
          logger.messages,
          contains(
              'WARNING: Context file not found: nonexistent_context.yaml'));
      expect(logger.messages,
          contains('WARNING: Context file not found: another_missing.json'));
    });

    test('loadContextFiles loads existing context files', () async {
      // Create a test context file
      final contextFile = fs.file('${tempDir.path}/context.yaml');
      await contextFile.writeAsString('test: content');

      final loader = EventLoader(
        eventsPath: eventsPath,
        contextFiles: [contextFile.path],
        log: logger,
        fs: fs,
      );

      final sources = await loader.loadContextFiles();

      expect(sources, hasLength(1));
      expect(sources.first.filePath, contextFile.path);
      expect(sources.first.content, 'test: content');
      expect(logger.messages, isEmpty); // No warnings for existing files
    });

    test('loadContextFiles handles mix of existing and missing files',
        () async {
      // Create one existing file
      final existingFile = fs.file('${tempDir.path}/existing.yaml');
      await existingFile.writeAsString('existing: content');

      final loader = EventLoader(
        eventsPath: eventsPath,
        contextFiles: [existingFile.path, 'missing.yaml'],
        log: logger,
        fs: fs,
      );

      final sources = await loader.loadContextFiles();

      expect(sources, hasLength(1));
      expect(sources.first.filePath, existingFile.path);
      expect(logger.messages,
          contains('WARNING: Context file not found: missing.yaml'));
      expect(logger.messages.where((msg) => msg.contains('WARNING')),
          hasLength(1));
    });

    test('loadSourceFile logs warning for missing file and returns null',
        () async {
      final loader = EventLoader(eventsPath: eventsPath, log: logger, fs: fs);

      final source = await loader.loadSourceFile('missing_file.yaml');

      expect(source, isNull);
      expect(logger.messages,
          contains('WARNING: File not found: missing_file.yaml'));
    });

    test('loadSourceFile loads existing file', () async {
      final file = fs.file('${tempDir.path}/shared.yaml');
      await file.writeAsString('shared: content');

      final loader = EventLoader(eventsPath: eventsPath, log: logger, fs: fs);
      final source = await loader.loadSourceFile(file.path);

      expect(source, isNotNull);
      expect(source!.filePath, file.path);
      expect(source.content, 'shared: content');
    });

    test('loadEventFiles warns when events directory missing', () async {
      final nonExistentPath = '${tempDir.path}/does_not_exist';
      final loader =
          EventLoader(eventsPath: nonExistentPath, log: logger, fs: fs);

      final sources = await loader.loadEventFiles();

      expect(sources, isEmpty);
      expect(logger.messages,
          contains('WARNING: Events directory not found at: $nonExistentPath'));
    });

    test('loadEventFiles returns YAML files and skips non-yaml', () async {
      final fileA = fs.file('${tempDir.path}/b.yaml');
      final fileB = fs.file('${tempDir.path}/a.yaml');
      final fileC = fs.file('${tempDir.path}/ignore.txt');
      await fileA.writeAsString('b: 1');
      await fileB.writeAsString('a: 2');
      await fileC.writeAsString('not yaml');

      final loader = EventLoader(eventsPath: eventsPath, log: logger, fs: fs);
      final sources = await loader.loadEventFiles();

      // Should only find the two YAML files and they should be sorted by filename
      expect(
          sources
              .map((s) => fs.file(s.filePath).uri.pathSegments.last)
              .toList(),
          equals(['a.yaml', 'b.yaml']));
      expect(logger.messages,
          contains('INFO: Found 2 YAML file(s) in $eventsPath'));
    });

    test(
        'loadEventFiles skips files present in contextFiles and sharedParameterFiles',
        () async {
      final eventFile = fs.file('${tempDir.path}/event.yaml');
      final contextFile = fs.file('${tempDir.path}/context.yaml');
      final sharedFile = fs.file('${tempDir.path}/shared.yaml');
      await eventFile.writeAsString('name: event');
      await contextFile.writeAsString('ctx: data');
      await sharedFile.writeAsString('shared: data');

      final loader = EventLoader(
        eventsPath: eventsPath,
        contextFiles: [contextFile.path],
        sharedParameterFiles: [sharedFile.path],
        log: logger,
        fs: fs,
      );

      final sources = await loader.loadEventFiles();

      expect(sources, hasLength(1));
      expect(sources.first.filePath, eventFile.path);
      expect(logger.messages,
          contains('INFO: Found 3 YAML file(s) in $eventsPath'));
    });
  });
}
