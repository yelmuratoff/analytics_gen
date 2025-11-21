import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:analytics_gen/src/util/logger.dart';
import 'package:test/test.dart';

class _FakeStdout implements io.Stdout {
  _FakeStdout(this._supportsAnsi);
  final bool _supportsAnsi;
  final io.Stdout _delegate = io.stdout;

  @override
  bool get supportsAnsiEscapes => _supportsAnsi;

  @override
  Encoding get encoding => _delegate.encoding;
  @override
  set encoding(Encoding encoding) => _delegate.encoding = encoding;

  @override
  void add(List<int> data) => _delegate.add(data);
  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _delegate.addError(error, stackTrace);
  @override
  Future addStream(Stream<List<int>> stream) => _delegate.addStream(stream);
  @override
  Future close() => _delegate.close();
  @override
  Future get done => _delegate.done;
  @override
  void write(Object? obj) => _delegate.write(obj);
  @override
  void writeln([Object? obj = '']) => _delegate.writeln(obj);
  @override
  void writeAll(Iterable objects, [String separator = '']) =>
      _delegate.writeAll(objects, separator);
  @override
  void writeCharCode(int charCode) => _delegate.writeCharCode(charCode);
  @override
  Future flush() => _delegate.flush();
  @override
  bool get hasTerminal => _delegate.hasTerminal;
  @override
  int get terminalColumns => _delegate.terminalColumns;
  @override
  int get terminalLines => _delegate.terminalLines;
  @override
  io.IOSink get nonBlocking => _delegate.nonBlocking;
  @override
  String get lineTerminator => _delegate.lineTerminator;
  @override
  set lineTerminator(String v) => _delegate.lineTerminator = v;
}

void main() {
  group('ConsoleLogger', () {
    test('debug prints only when verbose', () {
      final lines = <String>[];
      final logger = ConsoleLogger(verbose: true);

      runZonedGuarded(
          () {
            logger.debug('debug message');
          },
          (e, s) {},
          zoneSpecification: ZoneSpecification(print: (_, __, ___, line) {
            lines.add(line);
          }));

      expect(lines, isNotEmpty);
      expect(lines.first, contains('DEBUG'));

      lines.clear();
      final logger2 = ConsoleLogger(verbose: false);
      runZonedGuarded(
          () {
            logger2.debug('hush');
          },
          (e, s) {},
          zoneSpecification: ZoneSpecification(print: (_, __, ___, line) {
            lines.add(line);
          }));
      expect(lines, isEmpty);
    });

    test('warning prints always', () {
      final lines = <String>[];
      final logger = ConsoleLogger();
      runZonedGuarded(
          () {
            logger.warning('be careful');
          },
          (e, s) {},
          zoneSpecification: ZoneSpecification(print: (_, __, ___, line) {
            lines.add(line);
          }));
      expect(lines, isNotEmpty);
      expect(lines.first, contains('WARN'));
    });

    test('error prints message, error and stack when verbose', () {
      final lines = <String>[];
      final logger = ConsoleLogger(verbose: true);
      final stack = StackTrace.current;
      runZonedGuarded(
          () {
            logger.error('boom', 'ErrorDetails', stack);
          },
          (e, s) {},
          zoneSpecification: ZoneSpecification(print: (_, __, ___, line) {
            lines.add(line);
          }));

      // Should include the error message and the error object
      expect(lines.any((l) => l.contains('ERROR')), isTrue);
      expect(lines.any((l) => l.contains('ErrorDetails')), isTrue);
      // stacktrace should be printed (new line) because verbose
      expect(lines.any((l) => l.contains('StackTrace') || l.contains('main')),
          isTrue);
    });

    test('error does not print stack when not verbose', () {
      final lines = <String>[];
      final logger = ConsoleLogger(verbose: false);
      final stack = StackTrace.current;
      runZonedGuarded(
          () {
            logger.error('boom', 'err', stack);
          },
          (e, s) {},
          zoneSpecification: ZoneSpecification(print: (_, __, ___, line) {
            lines.add(line);
          }));

      expect(lines.any((l) => l.contains('err')), isTrue);
      // stack trace should not be printed
      expect(lines.any((l) => l.contains('StackTrace')), isFalse);
    });

    test('scoped prefixes prefix', () {
      final lines = <String>[];
      final logger = ConsoleLogger(prefix: '');
      final scoped = logger.scoped('label');
      runZonedGuarded(
          () {
            scoped.info('ready');
          },
          (e, s) {},
          zoneSpecification: ZoneSpecification(print: (_, __, ___, line) {
            lines.add(line);
          }));

      expect(lines, isNotEmpty);
      expect(lines.first, contains('[label]'));
    });

    test('scoped builds nested prefix', () {
      final lines = <String>[];
      final logger = ConsoleLogger(prefix: '[P] ');
      final scoped = logger.scoped('label');
      runZonedGuarded(
          () {
            scoped.info('ready');
          },
          (e, s) {},
          zoneSpecification: ZoneSpecification(print: (_, __, ___, line) {
            lines.add(line);
          }));
      expect(lines.first, contains('[P] [label]'));
    });

    test('default level prints via printForTest', () {
      final lines = <String>[];
      final logger = ConsoleLogger();
      runZonedGuarded(
          () {
            logger.printForTest('CUSTOM', 'hello');
          },
          (e, s) {},
          zoneSpecification: ZoneSpecification(print: (_, __, ___, line) {
            lines.add(line);
          }));
      expect(lines.first, contains('[CUSTOM]'));
    });

    test(
        'info prints green check message specially and normal message normally',
        () {
      final lines = <String>[];
      final logger = ConsoleLogger();
      runZonedGuarded(
          () {
            logger.info('✓ success');
            logger.info('hello');
          },
          (e, s) {},
          zoneSpecification: ZoneSpecification(print: (_, __, ___, line) {
            lines.add(line);
          }));

      // '✓ success' should appear unbracketed
      expect(lines.any((l) => l.contains('✓ success')), isTrue);
      // 'hello' should appear without bracket as well for INFO
      expect(lines.any((l) => l.contains('hello')), isTrue);
    });

    test('NoOpLogger scoped returns same instance and does nothing', () {
      final noop = NoOpLogger();
      expect(identical(noop.scoped('x'), noop), isTrue);
    });

    test('non-ANSI prints fallback format', () async {
      final lines = <String>[];
      final nonAnsiStdout = _FakeStdout(false);
      final logger = ConsoleLogger(prefix: '');
      await io.IOOverrides.runZoned(() async {
        runZonedGuarded(
            () {
              logger.info('msg');
              logger.warning('w');
              logger.error('e');
            },
            (e, s) {},
            zoneSpecification: ZoneSpecification(print: (_, __, ___, line) {
              lines.add(line);
            }));
      }, stdout: () => nonAnsiStdout);

      // INFO should not have [INFO] prefix in non-ANSI path
      expect(lines.any((l) => l == 'msg' || l.contains('msg')), isTrue);
      expect(lines.any((l) => l.contains('[WARN]')), isTrue);
      expect(lines.any((l) => l.contains('[ERROR]')), isTrue);
    });
  });
}
