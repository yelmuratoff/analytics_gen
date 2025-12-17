import 'package:path/path.dart' as path;

import 'generation_task.dart';

/// Task that generates the barrel file exporting all domain files.
class GenerateBarrelFileTask implements GenerationTask {
  @override
  Future<void> execute(GenerationContext context) async {
    final buffer = StringBuffer();

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Barrel file - exports all domain event files');
    buffer.writeln();

    // Export all domain files
    for (final domainName in context.domains.keys.toList()..sort()) {
      buffer.writeln("export 'events/${domainName}_events.dart';");
    }

    final barrelPath = path.join(context.outputDir, 'generated_events.dart');
    await context.outputManager.writeFileIfContentChanged(
      barrelPath,
      buffer.toString(),
    );
  }
}
