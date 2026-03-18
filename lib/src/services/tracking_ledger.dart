import 'dart:convert';
import 'dart:io';

/// Manages the `.analytics_tracking.json` ledger file that records
/// when each event was first seen by the generator.
final class TrackingLedger {
  /// Creates a new tracking ledger.
  TrackingLedger({
    required this.ledgerPath,
    DateTime Function()? clock,
  }) : _clock = clock;

  /// Absolute path to the ledger JSON file.
  final String ledgerPath;

  final DateTime Function()? _clock;

  String get _today {
    final now = _clock?.call() ?? DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Loads existing ledger entries from disk.
  ///
  /// Returns an empty map if the file does not exist or is empty.
  Future<Map<String, String>> load() async {
    final file = File(ledgerPath);
    if (!file.existsSync()) return {};
    final content = await file.readAsString();
    if (content.trim().isEmpty) return {};
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  }

  /// Saves ledger entries to disk with sorted keys.
  Future<void> save(Map<String, String> entries) async {
    final sorted = Map.fromEntries(
      entries.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final file = File(ledgerPath);
    await file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(sorted)}\n',
    );
  }

  /// Reconciles event keys against the ledger.
  ///
  /// New events get today's date. Existing entries are preserved.
  /// Returns the full map of all entries (including newly added ones).
  Future<Map<String, String>> reconcile(List<String> eventKeys) async {
    final entries = await load();
    var changed = false;
    for (final key in eventKeys) {
      if (!entries.containsKey(key)) {
        entries[key] = _today;
        changed = true;
      }
    }
    if (changed) await save(entries);
    return entries;
  }
}
