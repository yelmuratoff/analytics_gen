import 'dart:io';

import '../core/exceptions.dart';

/// Whether [error] reports invalid input that its message alone explains:
/// an [AnalyticsException], a [FormatException] from the tracking plan, the
/// config file or the command line, or a [FileSystemException] for a path
/// the user supplied.
bool isInvalidInputError(Object error) =>
    error is AnalyticsException ||
    error is FormatException ||
    error is FileSystemException;
