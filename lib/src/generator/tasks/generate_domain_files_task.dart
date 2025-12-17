import 'package:path/path.dart' as path;

import 'generation_task.dart';

/// Task that generates individual domain event files.
class GenerateDomainFilesTask implements GenerationTask {
  @override
  Future<void> execute(GenerationContext context) async {
    // Generate individual domain files with telemetry
    await Future.wait(context.domains.entries.map((entry) async {
      final domainName = entry.key;
      final domain = entry.value;

      final content = context.eventRenderer.renderDomainFile(
        domainName,
        domain,
        context.domains,
      );

      final fileName = '${domainName}_events.dart';
      final filePath = path.join(context.eventsDir, fileName);

      await context.outputManager.writeFileIfContentChanged(filePath, content);
      context.generatedFiles.add(filePath);
    }));

    context.logger.info('✓ Generated ${context.domains.length} domain files');
    context.logger.debug('  Domains: ${context.domains.keys.join(', ')}');
  }
}
