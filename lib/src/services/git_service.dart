import 'dart:io';

import '../util/logger.dart';

/// Information about a file or line commit history.
class GitCommitInfo {
  /// Creates a new commit info.
  const GitCommitInfo({
    required this.author,
    required this.date,
    required this.hash,
    required this.message,
  });

  /// The author name/email.
  final String author;

  /// The commit date.
  final DateTime date;

  /// The commit hash.
  final String hash;

  /// The commit message.
  final String message;
}

/// Service for interacting with git.
class GitService {
  /// Creates a new git service.
  const GitService({this.logger = const NoOpLogger()});

  /// The logger to use.
  final Logger logger;

  /// Retrieves the last commit info for a specific line in a file.
  Future<GitCommitInfo?> getBlame(String filePath, int lineNumber) async {
    try {
      // git blame -L n,n -p file
      final result = await Process.run(
        'git',
        [
          'blame',
          '-L',
          '$lineNumber,$lineNumber',
          '--line-porcelain',
          filePath
        ],
      );

      if (result.exitCode != 0) {
        return null;
      }

      final lines = (result.stdout as String).split('\n');
      String? hash;
      String? author;
      String? authorMail;
      int? timestamp;
      String? summary;

      for (final line in lines) {
        if (line.startsWith('author ')) {
          author = line.substring(7);
        } else if (line.startsWith('author-mail ')) {
          authorMail = line.substring(12);
        } else if (line.startsWith('author-time ')) {
          timestamp = int.tryParse(line.substring(12));
        } else if (line.startsWith('summary ')) {
          summary = line.substring(8);
        } else if (hash == null && line.isNotEmpty) {
          // First line is hash
          final parts = line.split(' ');
          if (parts.isNotEmpty) hash = parts.first;
        }
      }

      if (hash != null && author != null && timestamp != null) {
        return GitCommitInfo(
          hash: hash,
          author: '$author ${authorMail ?? ""}'.trim(),
          date: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
          message: summary ?? '',
        );
      }
      return null;
    } catch (e) {
      logger.debug('Git blame failed: $e');
      return null;
    }
  }
}
