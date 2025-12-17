import 'generation_task.dart';

/// Task that prepares the output directories.
class PrepareDirectoriesTask implements GenerationTask {
  @override
  Future<void> execute(GenerationContext context) async {
    context.logger.info('Starting analytics code generation...');

    await context.outputManager.prepareOutputDirectories(
      context.outputDir,
      context.eventsDir,
      context.contextsDir,
    );
  }
}
