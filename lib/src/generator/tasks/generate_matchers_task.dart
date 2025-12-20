import 'package:path/path.dart' as path;

import 'generation_task.dart';

/// Task that generates test matchers.
class GenerateMatchersTask implements GenerationTask {
  @override
  Future<void> execute(GenerationContext context) async {
    final content = context.matchersRenderer.render(context.domains);
    final matchersPath = path.join(
      context.projectRoot,
      'test',
      'analytics_matchers.dart',
    );

    // Ensure test directory exists
    final testDir =
        context.outputManager.fs.directory(path.dirname(matchersPath));
    if (!testDir.existsSync()) {
      await context.outputManager.fs
          .directory(testDir.path)
          .create(recursive: true);
    }

    await context.outputManager.writeFileIfContentChanged(
      matchersPath,
      content,
    );

    context.logger.info('✓ Generated matchers file at: $matchersPath');
  }
}
