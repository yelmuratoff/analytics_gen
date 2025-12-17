import 'package:path/path.dart' as path;

import '../generation_metadata.dart';
import 'generation_task.dart';

/// Task that generates the main Analytics class.
class GenerateAnalyticsClassTask implements GenerationTask {
  @override
  Future<void> execute(GenerationContext context) async {
    final metadata = GenerationMetadata.fromDomains(context.domains);

    final content = context.classRenderer.renderAnalyticsClass(
      context.domains,
      contexts: context.contexts,
      planFingerprint: metadata.fingerprint,
    );

    // Write to file
    final analyticsPath = path.join(
      context.outputDir,
      'analytics.dart',
    );

    await context.outputManager.writeFileIfContentChanged(
      analyticsPath,
      content,
    );

    context.logger.info('✓ Generated Analytics class at: $analyticsPath');
  }
}
