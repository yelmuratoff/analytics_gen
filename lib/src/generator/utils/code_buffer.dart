/// A buffer for generating code with automatic indentation.
class CodeBuffer {
  /// Creates a new code buffer.
  CodeBuffer({int initialIndent = 0}) : _indent = initialIndent;

  final StringBuffer _buffer = StringBuffer();
  int _indent;

  /// Increases indentation level.
  void indent() => _indent++;

  /// Decreases indentation level.
  void outdent() {
    if (_indent > 0) _indent--;
  }

  /// Writes [object] to the buffer.
  void write(Object? object) {
    if (object != null) {
      _buffer.write(object);
    }
  }

  /// Writes [object] to the buffer providing indentation for each line.
  void writeln([Object? object = '']) {
    final str = object.toString();
    if (str.isEmpty) {
      _buffer.writeln();
      return;
    }

    final lines = str.split('\n');
    for (final line in lines) {
      if (line.isNotEmpty) {
        _buffer.write('  ' * _indent);
      }
      _buffer.writeln(line);
    }
  }

  @override
  String toString() => _buffer.toString();
}
