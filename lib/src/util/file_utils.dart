import 'dart:io';

/// Writes file only if content has changed.
///
/// Returns true if the file was written, false if unchanged.
Future<bool> writeFileIfContentChanged(String filePath, String contents) async {
  final file = File(filePath);
  if (file.existsSync()) {
    final existing = await file.readAsString();
    if (existing == contents) return false;
  } else {
    await file.parent.create(recursive: true);
  }

  await file.writeAsString(contents);
  return true;
}
