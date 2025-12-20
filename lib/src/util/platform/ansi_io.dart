import 'dart:io' as io;

/// Returns whether the current environment supports ANSI escapes.
bool get supportsAnsiEscapes => io.stdout.supportsAnsiEscapes;
