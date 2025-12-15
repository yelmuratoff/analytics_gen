import 'dart:io';

import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/util/logger.dart';
import 'package:analytics_gen/src/util/schema_comparator.dart';
import 'package:path/path.dart' as path;

/// Checks for schema changes between runs.
class SchemaEvolutionChecker {
  /// Default constructor
  const SchemaEvolutionChecker({
    required this.projectRoot,
    required this.logger,
  });

  /// Project root directory.
  final String projectRoot;

  /// Logger instance.
  final Logger logger;

  /// Checks if the schema has changed compared to the previous export.
  ///
  /// [currentDomains] is the map of domains generated in the current run.
  /// [exportsPath] is the relative path to the folder containing the previous 'analytics_events.json'.
  Future<void> checkSchemaEvolution(
    Map<String, AnalyticsDomain> currentDomains,
    String? exportsPath,
  ) async {
    if (exportsPath == null) return;

    final jsonFile = File(path.join(
      projectRoot,
      exportsPath,
      'analytics_events.json',
    ));

    if (!jsonFile.existsSync()) {
      logger.debug('No previous schema found at ${jsonFile.path}');
      return;
    }

    try {
      final jsonContent = await jsonFile.readAsString();
      final previousDomains = SchemaComparator.loadSchemaFromJson(jsonContent);
      final changes =
          SchemaComparator().compare(currentDomains, previousDomains);

      if (changes.isEmpty) {
        logger.debug('No schema changes detected.');
        return;
      }

      final breakingChanges = changes.where((c) => c.isBreaking).toList();
      final nonBreakingChanges = changes.where((c) => !c.isBreaking).toList();

      if (nonBreakingChanges.isNotEmpty) {
        logger.info('Detected ${nonBreakingChanges.length} schema changes:');
        for (final change in nonBreakingChanges) {
          logger.info('  - $change');
        }
      }

      if (breakingChanges.isNotEmpty) {
        logger.warning(
            'Detected ${breakingChanges.length} BREAKING schema changes:');
        for (final change in breakingChanges) {
          logger.warning('  - $change');
        }
        // We could throw here if a strict flag was enabled
      }
    } catch (e) {
      logger.warning('Failed to check schema evolution: $e');
    }
  }
}
