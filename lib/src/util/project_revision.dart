import 'dart:convert';

/// Computes the project content revision — a deterministic hash mirrored in the
/// AnalyticsGen Studio (`analytics-gen-studio/src/utils/project-meta.ts`).
///
/// A studio-saved file and a CI-generated file share the same revision for
/// identical content, and regenerating from unchanged YAML yields a stable
/// value — so CI can compare revisions across commits.
///
/// The hash (cyrb53) runs over a canonical JSON serialization with recursively
/// sorted object keys, making it independent of key ordering.
String computeRevision(Object? content) {
  final canonical = jsonEncode(_canonicalize(content));
  return _cyrb53(canonical).toRadixString(16).padLeft(14, '0');
}

Object? _canonicalize(Object? value) {
  if (value is List) {
    return value.map(_canonicalize).toList();
  }
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    return {for (final key in keys) key: _canonicalize(value[key])};
  }
  return value;
}

/// cyrb53 — 53-bit string hash. Operates on UTF-16 code units with all math
/// masked to 32 bits so it reproduces the JavaScript implementation exactly.
int _cyrb53(String str, [int seed = 0]) {
  var h1 = (0xdeadbeef ^ seed) & 0xffffffff;
  var h2 = (0x41c6ce57 ^ seed) & 0xffffffff;
  for (var i = 0; i < str.length; i++) {
    final ch = str.codeUnitAt(i);
    h1 = _imul(h1 ^ ch, 2654435761);
    h2 = _imul(h2 ^ ch, 1597334677);
  }
  h1 = _imul(h1 ^ (h1 >>> 16), 2246822507);
  h1 = (h1 ^ _imul(h2 ^ (h2 >>> 13), 3266489909)) & 0xffffffff;
  h2 = _imul(h2 ^ (h2 >>> 16), 2246822507);
  h2 = (h2 ^ _imul(h1 ^ (h1 >>> 13), 3266489909)) & 0xffffffff;
  return 4294967296 * (2097151 & h2) + h1;
}

/// 32-bit integer multiply with overflow wrap — matches JavaScript `Math.imul`.
int _imul(int a, int b) {
  a &= 0xffffffff;
  b &= 0xffffffff;
  final ah = a >>> 16;
  final al = a & 0xffff;
  final bh = b >>> 16;
  final bl = b & 0xffff;
  final lo = al * bl;
  final mid = (((ah * bl + al * bh) & 0xffff) << 16) & 0xffffffff;
  return (lo + mid) & 0xffffffff;
}
