import 'dart:io';

import 'package:path/path.dart' as path;

import '../config/analytics_config.dart';
import '../models/analytics_event.dart';
import '../parser/yaml_parser.dart';

/// Generates Markdown documentation for analytics events.
final class DocsGenerator {
  final AnalyticsConfig config;
  final String projectRoot;
  final void Function(String message)? log;

  DocsGenerator({
    required this.config,
    required this.projectRoot,
    this.log,
  });

  /// Generates analytics documentation and writes to configured path
  Future<void> generate() async {
    log?.call('Starting analytics documentation generation...');

    // Parse YAML files
    final parser = YamlParser(
      eventsPath: path.join(projectRoot, config.eventsPath),
      log: log,
    );
    final domains = await parser.parseEvents();

    if (domains.isEmpty) {
      log?.call(
        'No analytics events found. Skipping documentation generation.',
      );
      return;
    }

    // Generate documentation
    final markdown = _generateMarkdown(domains);

    // Write to output file
    final outputPath =
        config.docsPath != null
            ? path.join(projectRoot, config.docsPath!)
            : path.join(projectRoot, 'analytics_docs.md');

    final outputFile = File(outputPath);
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(markdown);

    log?.call('✓ Generated analytics documentation at: $outputPath');

    // Print summary
    final totalEvents = domains.values.fold(0, (sum, d) => sum + d.eventCount);
    final totalParams = domains.values.fold(
      0,
      (sum, d) => sum + d.parameterCount,
    );
    log?.call(
      '✓ Documented $totalEvents events across ${domains.length} domains',
    );
    log?.call('  Total parameters: $totalParams');
  }

  /// Generates complete Markdown documentation
  String _generateMarkdown(Map<String, AnalyticsDomain> domains) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('# Analytics Events Documentation');
    buffer.writeln();
    buffer.writeln('Generated on: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    // Table of contents
    buffer.writeln('## Table of Contents');
    buffer.writeln();
    for (final domainName in domains.keys) {
      final anchor = domainName.toLowerCase().replaceAll('_', '-');
      buffer.writeln('- [$domainName](#$anchor)');
    }
    buffer.writeln();

    // Summary statistics
    final totalEvents = domains.values.fold(0, (sum, d) => sum + d.eventCount);
    final totalParams = domains.values.fold(
      0,
      (sum, d) => sum + d.parameterCount,
    );

    buffer.writeln('## Summary');
    buffer.writeln();
    buffer.writeln('- **Total Domains**: ${domains.length}');
    buffer.writeln('- **Total Events**: $totalEvents');
    buffer.writeln('- **Total Parameters**: $totalParams');
    buffer.writeln();

    // Generate documentation for each domain
    for (final entry in domains.entries) {
      buffer.write(_generateDomainDocs(entry.key, entry.value));
      buffer.writeln();
    }

    // Usage examples
    buffer.writeln('## Usage Examples');
    buffer.writeln();
    buffer.writeln('```dart');
    buffer.writeln("import 'package:analytics_gen/analytics_gen.dart';");
    buffer.writeln();
    buffer.writeln('// Initialize with your analytics provider');
    buffer.writeln('Analytics.initialize(yourAnalyticsService);');
    buffer.writeln();
    buffer.writeln('// Log events');
    if (domains.isNotEmpty) {
      final firstDomain = domains.values.first;
      if (firstDomain.events.isNotEmpty) {
        final firstEvent = firstDomain.events.first;
        final methodName = _createMethodName(firstDomain.name, firstEvent.name);

        if (firstEvent.parameters.isEmpty) {
          buffer.writeln('Analytics.instance.$methodName();');
        } else {
          buffer.writeln('Analytics.instance.$methodName(');
          for (final param in firstEvent.parameters) {
            final camelParam = _toCamelCase(param.name);
            buffer.writeln('  $camelParam: value,');
          }
          buffer.writeln(');');
        }
      }
    }
    buffer.writeln('```');
    buffer.writeln();

    return buffer.toString();
  }

  /// Generates documentation for a single domain
  String _generateDomainDocs(String domainName, AnalyticsDomain domain) {
    final buffer = StringBuffer();

    buffer.writeln('## $domainName');
    buffer.writeln();
    buffer.writeln(
      'Events: ${domain.eventCount} | Parameters: ${domain.parameterCount}',
    );
    buffer.writeln();

    // Create table
    buffer.writeln('| Event | Description | Parameters |');
    buffer.writeln('|-------|-------------|------------|');

    for (final event in domain.events) {
      final eventName = event.customEventName ?? '$domainName: ${event.name}';
      final params =
          event.parameters.isEmpty
              ? '-'
              : event.parameters
                  .map((p) {
                    final typeStr =
                        '`${p.name}` (${p.type}${p.isNullable ? '?' : ''})';
                    return p.description != null
                        ? '$typeStr: ${p.description}'
                        : typeStr;
                  })
                  .join('<br>');

      buffer.writeln('| $eventName | ${event.description} | $params |');
    }

    buffer.writeln();

    // Code examples for this domain
    buffer.writeln('### Code Examples');
    buffer.writeln();
    buffer.writeln('```dart');

    for (final event in domain.events.take(3)) {
      // Show max 3 examples
      final methodName = _createMethodName(domainName, event.name);

      if (event.parameters.isEmpty) {
        buffer.writeln('Analytics.instance.$methodName();');
      } else {
        buffer.writeln('Analytics.instance.$methodName(');
        for (final param in event.parameters) {
          final camelParam = _toCamelCase(param.name);
          final example = _getExampleValue(param.type, param.isNullable);
          buffer.writeln('  $camelParam: $example,');
        }
        buffer.writeln(');');
      }
      buffer.writeln();
    }

    buffer.writeln('```');

    return buffer.toString();
  }

  /// Creates a method name from domain and event names
  String _createMethodName(String domain, String eventName) {
    final capitalizedDomain = _capitalize(domain);
    final parts = eventName.split('_');
    final capitalizedEvent =
        parts.first + parts.skip(1).map((p) => _capitalize(p)).join();

    return 'log$capitalizedDomain${_capitalize(capitalizedEvent)}';
  }

  /// Capitalizes first letter and handles snake_case
  String _capitalize(String text) {
    if (text.isEmpty) return text;

    if (text.contains('_')) {
      return text
          .split('_')
          .map((part) {
            if (part.isEmpty) return '';
            return part[0].toUpperCase() + part.substring(1);
          })
          .join('');
    }

    return text[0].toUpperCase() + text.substring(1);
  }

  /// Converts snake_case to camelCase
  String _toCamelCase(String text) {
    if (text.isEmpty) return text;
    final parts = text.split(RegExp(r'[_-]'));
    return parts.first +
        parts.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join();
  }

  /// Gets an example value for documentation
  String _getExampleValue(String type, bool isNullable) {
    if (isNullable) {
      return 'null';
    }

    switch (type.toLowerCase()) {
      case 'int':
        return '123';
      case 'bool':
        return 'true';
      case 'double':
      case 'float':
        return '1.5';
      case 'string':
        return "'example'";
      case 'map':
        return "{'key': 'value'}";
      case 'list':
        return "['item1', 'item2']";
      default:
        return 'value';
    }
  }
}
