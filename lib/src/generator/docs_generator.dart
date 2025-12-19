import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:path/path.dart' as path;

import '../config/analytics_config.dart';
import '../models/analytics_event.dart';
import '../util/event_naming.dart';
import '../util/logger.dart';
import '../util/string_utils.dart';
import '../util/type_mapper.dart';
import 'generation_metadata.dart';
import 'output_manager.dart';
import 'renderers/enum_renderer.dart';

/// Generates Markdown documentation for analytics events.
final class DocsGenerator {
  /// Creates a new docs generator.
  DocsGenerator({
    required this.config,
    required this.projectRoot,
    this.log = const NoOpLogger(),
    this.outputManager = const OutputManager(),
  });

  /// The analytics configuration.
  final AnalyticsConfig config;

  /// The root directory of the project.
  final String projectRoot;

  /// The logger to use.
  final Logger log;

  /// The output manager to use.
  final OutputManager outputManager;

  /// Generates analytics documentation and writes to configured path
  Future<void> generate(
    Map<String, AnalyticsDomain> domains, {
    Map<String, List<AnalyticsParameter>> contexts = const {},
  }) async {
    log.info('Starting analytics documentation generation...');

    if (domains.isEmpty && contexts.isEmpty) {
      log.warning(
        'No analytics events or properties found. Skipping documentation generation.',
      );
      return;
    }

    final metadata = GenerationMetadata.fromDomains(domains);

    // Generate documentation
    final markdown = _generateMarkdown(
      domains,
      metadata,
      contexts,
    );

    // Write to output file
    final outputPath = config.outputs.docsPath != null
        ? path.join(projectRoot, config.outputs.docsPath!)
        : path.join(projectRoot, 'analytics_docs.md');

    await outputManager.writeFileIfContentChanged(outputPath, markdown);

    log.info('✓ Generated analytics documentation at: $outputPath');

    // Print summary
    log.info(
      '✓ Documented ${metadata.totalEvents} events across '
      '${metadata.totalDomains} domains',
    );
    log.debug('  Total parameters: ${metadata.totalParameters}');
  }

  /// Generates complete Markdown documentation
  String _generateMarkdown(
    Map<String, AnalyticsDomain> domains,
    GenerationMetadata metadata,
    Map<String, List<AnalyticsParameter>> contexts,
  ) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('# Analytics Events Documentation');
    buffer.writeln();
    buffer.writeln('Fingerprint: `${metadata.fingerprint}`');
    buffer.writeln(
      'Domains: ${metadata.totalDomains} | '
      'Events: ${metadata.totalEvents} | '
      'Parameters: ${metadata.totalParameters}',
    );
    buffer.writeln();

    // Table of contents
    buffer.writeln('## Table of Contents');
    buffer.writeln();
    for (final domainName in domains.keys) {
      final anchor = domainName.toLowerCase().replaceAll('_', '-');
      buffer.writeln('- [$domainName](#$anchor)');
    }
    for (final contextName in contexts.keys) {
      final title = _getContextTitle(contextName);
      final anchor = title.toLowerCase().replaceAll(' ', '-');
      buffer.writeln('- [$title](#$anchor)');
    }
    buffer.writeln();

    // Summary statistics
    buffer.writeln('## Summary');
    buffer.writeln();
    buffer.writeln('- **Total Domains**: ${metadata.totalDomains}');
    buffer.writeln('- **Total Events**: ${metadata.totalEvents}');
    buffer.writeln('- **Total Parameters**: ${metadata.totalParameters}');
    buffer.writeln();

    // Generate documentation for each domain
    for (final entry in domains.entries) {
      buffer.write(_generateDomainDocs(entry.key, entry.value));
      buffer.writeln();
    }

    for (final entry in contexts.entries) {
      buffer.write(
          _generatePropertiesDocs(_getContextTitle(entry.key), entry.value));
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
        final methodName = EventNaming.buildLoggerMethodName(
          firstDomain.name,
          firstEvent.name,
        );

        if (firstEvent.parameters.isEmpty) {
          buffer.writeln('Analytics.instance.$methodName();');
        } else {
          buffer.writeln('Analytics.instance.$methodName(');
          for (final param in firstEvent.parameters) {
            final camelParam = _toCamelCase(param.codeName);
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

  String _getContextTitle(String contextName) {
    if (contextName == 'user_properties') return 'User Properties';
    if (contextName == 'global_context') return 'Global Context';
    return StringUtils.capitalizePascal(contextName);
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
    buffer.writeln('| Event | Description | Status | Parameters | Metadata |');
    buffer.writeln('|-------|-------------|--------|------------|----------|');

    for (final event in domain.events) {
      final eventName =
          EventNaming.resolveEventName(domainName, event, config.naming);
      final params = event.parameters.isEmpty
          ? '-'
          : event.parameters.map((p) {
              final typeStr =
                  '`${p.name}` (${_formatParameterType(domainName, event, p)})';
              final desc = p.description != null ? ': ${p.description}' : '';
              final allowed =
                  (p.allowedValues != null && p.allowedValues!.isNotEmpty)
                      ? ' (allowed: ${p.allowedValues!.join(', ')})'
                      : '';
              final meta = p.meta.isNotEmpty
                  ? ' [${p.meta.entries.map((e) => '${e.key}: ${e.value}').join(', ')}]'
                  : '';
              return '$typeStr$desc$allowed$meta';
            }).join('<br>');
      final status = _formatEventStatus(event);
      final meta = event.meta.isEmpty
          ? '-'
          : event.meta.entries
              .map((e) => '**${e.key}**: ${e.value}')
              .join('<br>');

      buffer.writeln(
        '| ${_escapeMarkdownCell(eventName)} | '
        '${_escapeMarkdownCell(event.description)} | '
        '${_escapeMarkdownCell(status)} | '
        '${_escapeMarkdownCell(params)} | '
        '${_escapeMarkdownCell(meta)} |',
      );
    }

    buffer.writeln();

    // Code examples for this domain
    buffer.writeln('### Code Examples');
    buffer.writeln();
    buffer.writeln('```dart');

    for (final event in domain.events.take(3)) {
      // Show max 3 examples
      final methodName = EventNaming.buildLoggerMethodName(
        domainName,
        event.name,
      );

      if (event.parameters.isEmpty) {
        buffer.writeln('Analytics.instance.$methodName();');
      } else {
        buffer.writeln('Analytics.instance.$methodName(');
        for (final param in event.parameters) {
          final camelParam = _toCamelCase(param.codeName);
          final example = _getExampleValue(domainName, event, param);
          buffer.writeln('  $camelParam: $example,');
        }
        buffer.writeln(');');
      }
      buffer.writeln();
    }

    buffer.writeln('```');

    return buffer.toString();
  }

  String _generatePropertiesDocs(
    String title,
    List<AnalyticsParameter> properties,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('## $title');
    buffer.writeln();
    buffer.writeln('Count: ${properties.length}');
    buffer.writeln();

    buffer.writeln(
        '| Property | Type | Description | Allowed Values | Metadata |');
    buffer.writeln(
        '|----------|------|-------------|----------------|----------|');

    for (final prop in properties) {
      final name = prop.name;
      final type =
          '${DartTypeMapper.toDartType(prop.type)}${prop.isNullable ? '?' : ''}';
      final desc = prop.description ?? '-';
      final allowed =
          (prop.allowedValues != null && prop.allowedValues!.isNotEmpty)
              ? prop.allowedValues!.join(', ')
              : '-';
      final meta = prop.meta.isEmpty
          ? '-'
          : prop.meta.entries
              .map((e) => '**${e.key}**: ${e.value}')
              .join('<br>');

      buffer.writeln(
        '| ${_escapeMarkdownCell(name)} | '
        '${_escapeMarkdownCell(type)} | '
        '${_escapeMarkdownCell(desc)} | '
        '${_escapeMarkdownCell(allowed)} | '
        '${_escapeMarkdownCell(meta)} |',
      );
    }

    return buffer.toString();
  }

  /// Converts snake_case to camelCase
  String _toCamelCase(String text) {
    return StringUtils.toCamelCase(text);
  }

  bool _isGeneratedEnumParameter(AnalyticsParameter param) {
    return param.dartType == null &&
        param.type == 'string' &&
        (param.allowedValues != null && param.allowedValues!.isNotEmpty);
  }

  String _formatParameterType(
    String domainName,
    AnalyticsEvent event,
    AnalyticsParameter param,
  ) {
    final explicitType = param.dartType;
    if (explicitType != null && explicitType.trim().isNotEmpty) {
      return '${explicitType.trim()}${param.isNullable ? '?' : ''}';
    }

    if (_isGeneratedEnumParameter(param)) {
      final enumName =
          const EnumRenderer().buildEnumName(domainName, event, param);
      return '$enumName${param.isNullable ? '?' : ''}';
    }

    final dartType = DartTypeMapper.toDartType(param.type);
    return '$dartType${param.isNullable ? '?' : ''}';
  }

  /// Gets an example value for documentation
  String _getExampleValue(
    String domainName,
    AnalyticsEvent event,
    AnalyticsParameter param,
  ) {
    if (param.isNullable) {
      return 'null';
    }

    final explicitType = param.dartType;
    if (explicitType != null && explicitType.trim().isNotEmpty) {
      return '${explicitType.trim()}.values.first';
    }

    if (_isGeneratedEnumParameter(param)) {
      final allowedValues = param.allowedValues;
      if (allowedValues != null && allowedValues.isNotEmpty) {
        final enumName =
            const EnumRenderer().buildEnumName(domainName, event, param);
        final firstValue = allowedValues.first.toString();
        final enumValue = const EnumRenderer().toEnumIdentifier(firstValue);
        return '$enumName.$enumValue';
      }
    }

    final rawType = param.type.trim();
    final normalizedType = rawType.toLowerCase();

    return switch (normalizedType) {
      'int' => '123',
      'bool' => 'true',
      'double' || 'float' => '1.5',
      'string' => "'example'",
      'datetime' || 'date' => 'DateTime.fromMillisecondsSinceEpoch(0)',
      'uri' => "Uri.parse('https://example.com')",
      'map' => "{'key': 'value'}",
      _ when normalizedType.startsWith('map<') => "{'key': 'value'}",
      'list' => "['item1', 'item2']",
      _ when normalizedType.startsWith('list<') => "['item1', 'item2']",
      _ => 'value',
    };
  }

  String _formatEventStatus(AnalyticsEvent event) {
    if (!event.deprecated) {
      return 'Active';
    }

    final replacement = event.replacement;
    if (replacement != null && replacement.isNotEmpty) {
      return '**Deprecated** -> `$replacement`';
    }

    return '**Deprecated**';
  }

  String _escapeMarkdownCell(String text) {
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    return normalized.replaceAll('|', '\\|').replaceAll('\n', '<br>');
  }
}
