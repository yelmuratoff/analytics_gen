import 'dart:convert';
import 'dart:io';

import 'package:analytics_gen/src/services/tracking_ledger.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('TrackingLedger', () {
    late Directory tempDir;
    late String ledgerPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('tracking_ledger_');
      ledgerPath = path.join(tempDir.path, '.analytics_tracking.json');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    TrackingLedger createLedger({DateTime Function()? clock}) {
      return TrackingLedger(ledgerPath: ledgerPath, clock: clock);
    }

    test('load returns empty map when file does not exist', () async {
      final ledger = createLedger();
      final entries = await ledger.load();
      expect(entries, isEmpty);
    });

    test('load returns empty map when file is empty', () async {
      await File(ledgerPath).writeAsString('');
      final ledger = createLedger();
      final entries = await ledger.load();
      expect(entries, isEmpty);
    });

    test('load returns parsed entries from existing file', () async {
      await File(ledgerPath).writeAsString(jsonEncode({
        'auth.login': '2026-01-15',
        'auth.logout': '2026-02-20',
      }));

      final ledger = createLedger();
      final entries = await ledger.load();

      expect(entries, {
        'auth.login': '2026-01-15',
        'auth.logout': '2026-02-20',
      });
    });

    test('save writes sorted JSON with trailing newline', () async {
      final ledger = createLedger();
      await ledger.save({
        'z_domain.event': '2026-03-01',
        'a_domain.event': '2026-01-01',
      });

      final content = await File(ledgerPath).readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;

      // Keys are sorted
      expect(decoded.keys.toList(), ['a_domain.event', 'z_domain.event']);

      // Formatted with indentation
      expect(content, contains('  '));

      // Trailing newline
      expect(content.endsWith('\n'), isTrue);
    });

    test('reconcile adds missing keys with today\'s date', () async {
      final fixedDate = DateTime(2026, 3, 18);
      final ledger = createLedger(clock: () => fixedDate);

      final entries = await ledger.reconcile([
        'auth.login',
        'auth.logout',
      ]);

      expect(entries, {
        'auth.login': '2026-03-18',
        'auth.logout': '2026-03-18',
      });

      // Verify file was written
      final onDisk = await ledger.load();
      expect(onDisk, entries);
    });

    test('reconcile preserves existing entries', () async {
      await File(ledgerPath).writeAsString(jsonEncode({
        'auth.login': '2026-01-15',
      }));

      final fixedDate = DateTime(2026, 3, 18);
      final ledger = createLedger(clock: () => fixedDate);

      final entries = await ledger.reconcile([
        'auth.login',
        'auth.logout',
      ]);

      expect(entries['auth.login'], '2026-01-15'); // preserved
      expect(entries['auth.logout'], '2026-03-18'); // new
    });

    test('reconcile does not overwrite existing dates', () async {
      await File(ledgerPath).writeAsString(jsonEncode({
        'auth.login': '2025-06-01',
      }));

      final ledger = createLedger(clock: () => DateTime(2026, 3, 18));

      final entries = await ledger.reconcile(['auth.login']);

      expect(entries['auth.login'], '2025-06-01');
    });

    test('reconcile leaves removed event entries in place', () async {
      await File(ledgerPath).writeAsString(jsonEncode({
        'auth.login': '2026-01-15',
        'auth.deleted_event': '2026-02-01',
      }));

      final ledger = createLedger(clock: () => DateTime(2026, 3, 18));

      // Only reconcile 'auth.login', but 'auth.deleted_event' should remain
      final entries = await ledger.reconcile(['auth.login']);

      expect(entries['auth.login'], '2026-01-15');
      expect(entries['auth.deleted_event'], '2026-02-01');
    });

    test('reconcile does not write file when nothing changed', () async {
      await File(ledgerPath).writeAsString(jsonEncode({
        'auth.login': '2026-01-15',
      }));
      final lastModified = await File(ledgerPath).lastModified();

      final ledger = createLedger();

      // Small delay to detect file write
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await ledger.reconcile(['auth.login']);

      final newModified = await File(ledgerPath).lastModified();
      expect(newModified, equals(lastModified));
    });

    test('reconcile formats date with zero-padded month and day', () async {
      final ledger = createLedger(clock: () => DateTime(2026, 1, 5));

      final entries = await ledger.reconcile(['auth.login']);

      expect(entries['auth.login'], '2026-01-05');
    });
  });
}
