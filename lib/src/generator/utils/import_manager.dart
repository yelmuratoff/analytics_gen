/// Manages distinct imports and handles sorting (Dart -> Package -> Relative).
class ImportManager {
  final Set<String> _imports = {};

  /// Adds a single import URI.
  void add(String uri) {
    _imports.add(uri);
  }

  /// Adds multiple import URIs.
  void addAll(Iterable<String> uris) {
    _imports.addAll(uris);
  }

  /// Returns the sorted list of imports.
  ///
  /// Order:
  /// 1. Dart SDK imports (dart:*)
  /// 2. Package imports (package:*)
  /// 3. Relative imports (everything else)
  List<String> getSortedImports() {
    final dartImports = <String>[];
    final packageImports = <String>[];
    final relativeImports = <String>[];

    for (final uri in _imports) {
      if (uri.startsWith('dart:')) {
        dartImports.add(uri);
      } else if (uri.startsWith('package:')) {
        packageImports.add(uri);
      } else {
        relativeImports.add(uri);
      }
    }

    dartImports.sort();
    packageImports.sort();
    relativeImports.sort();

    return [
      ...dartImports,
      ...packageImports,
      ...relativeImports,
    ];
  }
}
