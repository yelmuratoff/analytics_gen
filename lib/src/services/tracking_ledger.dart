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

  String get _timestamp {
    final now = _clock?.call() ?? DateTime.now();
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:$s';
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
  /// New events get the current timestamp. Existing entries are preserved.
  /// Returns the full map of all entries (including newly added ones).
  Future<Map<String, String>> reconcile(List<String> eventKeys) async {
    final entries = await load();
    var changed = false;
    for (final key in eventKeys) {
      if (!entries.containsKey(key)) {
        entries[key] = _timestamp;
        changed = true;
      }
    }
    if (changed) await save(entries);
    return entries;
  }
}
