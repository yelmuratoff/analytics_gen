import 'dart:io';

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/generation_metadata.dart';
import 'package:analytics_gen/src/pipeline/tracking_plan_loader.dart';
import 'package:analytics_gen/src/util/banner_printer.dart';
import 'package:analytics_gen/src/util/event_naming.dart';
import 'package:analytics_gen/src/util/logger.dart';

/// Validates the tracking plan without generating any files.
Future<void> validateTrackingPlan(
  String projectRoot,
  AnalyticsConfig config, {
  required Logger logger,
}) async {
  printBanner('Analytics Gen - Validation Only', logger: logger);
  logger.info('');

  final loader = TrackingPlanLoader(
    projectRoot: projectRoot,
    config: config,
  );

  try {
    final plan = await loader.load(logger);
    final domains = plan.domains;

    if (domains.isEmpty) {
      logger.info('No analytics events found.');
    } else {
      logger.info('✓ Validation successful.');
      logger.info('  Domains: ${domains.length}');
      logger.info('  Events: ${plan.totalEvents}');
      logger.info('  Parameters: ${plan.totalParameters}');
    }
  } catch (e, stack) {
    logger.error('✗ Validation failed: $e', null, stack);
    exit(1);
  }
}

/// Prints a summary of the tracking plan to the console.
Future<void> printTrackingPlan(
  String projectRoot,
  AnalyticsConfig config, {
  required Logger logger,
}) async {
  printBanner('Analytics Gen - Tracking Plan Overview', logger: logger);
  logger.info('');

  final loader = TrackingPlanLoader(
    projectRoot: projectRoot,
    config: config,
  );

  try {
    final plan = await loader.load(logger);
    final domains = plan.domains;

    if (domains.isEmpty) {
      logger.info('No analytics events are defined yet.');
      return;
    }

    final metadata = GenerationMetadata.fromDomains(domains);

    logger.info('Fingerprint: ${metadata.fingerprint}');
    logger.info(
      'Domains: ${metadata.totalDomains} | '
      'Events: ${metadata.totalEvents} | '
      'Parameters: ${metadata.totalParameters}',
    );

    final sortedDomains = domains.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in sortedDomains) {
      final domain = entry.value;
      logger.info('');
      logger.info(
        '- ${domain.name} '
        '(${domain.eventCount} events, ${domain.parameterCount} parameters)',
      );

      for (final event in domain.events) {
        final effectiveName = EventNaming.resolveEventName(
          domain.name,
          event,
          config.naming,
        );
        final status = event.deprecated
            ? 'DEPRECATED${event.replacement != null ? ' -> ${event.replacement}' : ''}'
            : 'Active';
        final params = event.parameters.map((param) {
          final nullableSuffix = param.isNullable ? '?' : '';
          return '${param.name} (${param.type}$nullableSuffix)';
        }).join(', ');

        logger.info('    • $effectiveName [$status]');
        if (params.isEmpty) {
          logger.info('      - No parameters');
        } else {
          logger.info('      - Parameters: $params');
        }
      }
    }
  } catch (e, stack) {
    logger.error('✗ Unable to print tracking plan: $e', null, stack);
    exit(1);
  }
}
