import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/generation_metadata.dart';
import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:analytics_gen/src/util/event_naming.dart';

import 'banner_printer.dart';

Future<void> validateTrackingPlan(
  String projectRoot,
  AnalyticsConfig config, {
  required bool verbose,
}) async {
  printBanner('Analytics Gen - Validation Only');
  print('');

  final parser = YamlParser(
    eventsPath: path.join(projectRoot, config.eventsPath),
    log: verbose ? (message) => print(message) : null,
    naming: config.naming,
  );

  try {
    final domains = await parser.parseEvents();

    if (domains.isEmpty) {
      print('No analytics events found.');
    } else {
      final totalEvents =
          domains.values.fold(0, (sum, d) => sum + d.eventCount);
      final totalParams =
          domains.values.fold(0, (sum, d) => sum + d.parameterCount);

      print('✓ Validation successful.');
      print('  Domains: ${domains.length}');
      print('  Events: $totalEvents');
      print('  Parameters: $totalParams');
    }
  } catch (e, stack) {
    print('✗ Validation failed: $e');
    if (verbose) {
      print('Stack trace: $stack');
    }
    exit(1);
  }
}

Future<void> printTrackingPlan(
  String projectRoot,
  AnalyticsConfig config, {
  required bool verbose,
}) async {
  printBanner('Analytics Gen - Tracking Plan Overview');
  print('');

  final parser = YamlParser(
    eventsPath: path.join(projectRoot, config.eventsPath),
    log: verbose ? (message) => print(message) : null,
    naming: config.naming,
  );

  try {
    final domains = await parser.parseEvents();

    if (domains.isEmpty) {
      print('No analytics events are defined yet.');
      return;
    }

    final metadata = GenerationMetadata.fromDomains(domains);

    print('Fingerprint: ${metadata.fingerprint}');
    print(
      'Domains: ${metadata.totalDomains} | '
      'Events: ${metadata.totalEvents} | '
      'Parameters: ${metadata.totalParameters}',
    );

    final sortedDomains = domains.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in sortedDomains) {
      final domain = entry.value;
      print('');
      print(
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

        print('    • $effectiveName [$status]');
        if (params.isEmpty) {
          print('      - No parameters');
        } else {
          print('      - Parameters: $params');
        }
      }
    }
  } catch (e, stack) {
    print('✗ Unable to print tracking plan: $e');
    if (verbose) {
      print('Stack trace: $stack');
    }
    exit(1);
  }
}
