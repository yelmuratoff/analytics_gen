import 'generation_task.dart';

/// Task that cleans up stale files in the output directory.
class CleanStaleFilesTask implements GenerationTask {
  @override
  Future<void> execute(GenerationContext context) async {
    // Clean up stale files in events and contexts directories
    await Future.wait([
      context.outputManager.cleanStaleFiles(
        context.eventsDir,
        context.generatedFiles,
      ),
      context.outputManager.cleanStaleFiles(
        context.contextsDir,
        context.generatedFiles,
      ),
    ]);
  }
}
