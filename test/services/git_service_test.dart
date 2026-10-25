import 'dart:io';

import 'package:analytics_gen/src/services/git_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('GitService.getBlame', () {
    late Directory repo;

    void git(List<String> args) {
      final result = Process.runSync(
        'git',
        [
          '-c',
          'user.name=Plan Author',
          '-c',
          'user.email=author@example.com',
          ...args,
        ],
        workingDirectory: repo.path,
      );
      if (result.exitCode != 0) throw StateError('${result.stderr}');
    }

    setUp(() {
      repo = Directory.systemTemp.createTempSync('git_service_');
    });

    tearDown(() => repo.deleteSync(recursive: true));

    test('returns the commit that last changed a line in another repository',
        () async {
      git(['init', '--quiet']);
      final file = File(p.join(repo.path, 'events.yaml'))
        ..writeAsStringSync('auth:\n  login: {}\n');
      git(['add', 'events.yaml']);
      git(['commit', '--quiet', '-m', 'Add login event']);

      final blame = await const GitService().getBlame(file.path, 2);

      expect(blame, isNotNull);
      expect(blame!.author, 'Plan Author <author@example.com>');
      expect(blame.message, 'Add login event');
      expect(blame.hash, hasLength(40));
    }, skip: _gitMissing() ? 'git is not installed' : false);

    test('returns null for a file outside any repository', () async {
      final file = File(p.join(repo.path, 'events.yaml'))
        ..writeAsStringSync('auth: {}\n');

      expect(await const GitService().getBlame(file.path, 1), isNull);
    });
  });
}

bool _gitMissing() {
  try {
    return Process.runSync('git', ['--version']).exitCode != 0;
  } on ProcessException {
    return true;
  }
}
