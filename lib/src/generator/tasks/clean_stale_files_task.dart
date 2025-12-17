import 'generation_task.dart';

/// Task that cleans up stale files in the output directory.
class CleanStaleFilesTask implements GenerationTask {
  @override
  Future<void> execute(GenerationContext context) async {
    // Clean up stale files in events directory
    // Note: Only event files are currently tracked for cleanup
    await context.outputManager.cleanStaleFiles(
      context.eventsDir,
      context.generatedFiles,
    );
  }
}
