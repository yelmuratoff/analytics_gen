import 'package:path/path.dart' as path;

import 'generation_task.dart';

/// Task that generates context definitions files.
class GenerateContextFilesTask implements GenerationTask {
  @override
  Future<void> execute(GenerationContext context) async {
    for (final entry in context.contexts.entries) {
      final contextName = entry.key;
      final properties = entry.value;

      final content = context.contextRenderer.renderContextFile(
        contextName,
        properties,
      );

      final fileName = '${contextName}_context.dart';
      final filePath = path.join(context.contextsDir, fileName);

      await context.outputManager.writeFileIfContentChanged(filePath, content);
      context.generatedFiles.add(filePath);
    }
  }
}
