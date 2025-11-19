import 'dart:io';

import 'package:path/path.dart' as path;

import '../config/analytics_config.dart';
import '../models/analytics_event.dart';
import '../util/event_naming.dart';
import '../util/string_utils.dart';
import '../util/type_mapper.dart';
import '../util/file_utils.dart';

/// Generates Dart code for analytics events from YAML configuration.
final class CodeGenerator {
  final AnalyticsConfig config;
  final String projectRoot;
  final void Function(String message)? log;

  CodeGenerator({
    required this.config,
    required this.projectRoot,
    this.log,
  });

  /// Generates analytics code and writes to configured output path
  Future<void> generate(Map<String, AnalyticsDomain> domains) async {
    log?.call('Starting analytics code generation...');

    if (domains.isEmpty) {
      log?.call('No analytics events found. Skipping generation.');
      return;
    }

    final outputDir = path.join(projectRoot, 'lib', config.outputPath);
    final eventsDir = path.join(outputDir, 'events');

    // Ensure output directories exist
    await _prepareOutputDirectories(outputDir, eventsDir);

    // Track generated files to clean up stale ones later
    final generatedFiles = <String>{};

    // Generate individual domain files in parallel
    await Future.wait(domains.entries.map((entry) async {
      final filePath =
          await _generateDomainFile(entry.key, entry.value, eventsDir);
      generatedFiles.add(filePath);
    }));

    // Clean up stale files
    await _cleanStaleFiles(eventsDir, generatedFiles);

    // Generate barrel file with all exports
    await _generateBarrelFile(domains, outputDir);

    log?.call('✓ Generated ${domains.length} domain files');
    log?.call('  Domains: ${domains.keys.join(', ')}');

    // Generate Analytics singleton class
    await _generateAnalyticsClass(domains);
  }

  /// Generates a separate file for a single domain and returns the file path
  Future<String> _generateDomainFile(
    String domainName,
    AnalyticsDomain domain,
    String eventsDir,
  ) async {
    final buffer = StringBuffer();

    // File header
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// ignore_for_file: type=lint, unused_import');
    buffer.writeln(
      '// ignore_for_file: directives_ordering, unnecessary_string_interpolations',
    );
    buffer.writeln('// coverage:ignore-file');
    buffer.writeln();
    buffer.writeln("import 'package:analytics_gen/analytics_gen.dart';");
    buffer.writeln();

    // Generate mixin
    buffer.write(_generateDomainMixin(domainName, domain));

    // Write to file
    final fileName = '${domainName}_events.dart';
    final filePath = path.join(eventsDir, fileName);
    await _writeFileIfContentChanged(filePath, buffer.toString());
    return filePath;
  }

  /// Generates barrel file that exports all domain event files
  Future<void> _generateBarrelFile(
    Map<String, AnalyticsDomain> domains,
    String outputDir,
  ) async {
    final buffer = StringBuffer();

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Barrel file - exports all domain event files');
    buffer.writeln();

    // Export all domain files
    for (final domainName in domains.keys.toList()..sort()) {
      buffer.writeln("export 'events/${domainName}_events.dart';");
    }

    final barrelPath = path.join(outputDir, 'generated_events.dart');
    await _writeFileIfContentChanged(barrelPath, buffer.toString());
  }

  /// Generates a mixin for a single domain
  String _generateDomainMixin(String domainName, AnalyticsDomain domain) {
    final buffer = StringBuffer();
    final className = 'Analytics${StringUtils.capitalizePascal(domainName)}';

    buffer.writeln('/// Generated mixin for $domainName analytics events');
    buffer.writeln('mixin $className on AnalyticsBase {');

    for (final event in domain.events) {
      buffer.write(_generateEventMethod(domainName, event));
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generates a method for a single event
  String _generateEventMethod(String domainName, AnalyticsEvent event) {
    final buffer = StringBuffer();
    final methodName = EventNaming.buildLoggerMethodName(
      domainName,
      event.name,
    );

    // Deprecation annotation
    if (event.deprecated) {
      final message = _buildDeprecationMessage(event);
      buffer.writeln("  @Deprecated('$message')");
    }

    // Documentation
    buffer.writeln('  /// ${event.description}');
    buffer.writeln('  ///');

    // We'll add the event 'description' to the logged parameters if the
    // configuration enables it and the description is present. This does not
    // affect the method signature - it's only an additional parameter in the
    // logged map.
    final includeDescription =
        config.includeEventDescription && event.description.isNotEmpty;

    if (event.parameters.isNotEmpty) {
      buffer.writeln('  /// Parameters:');
      for (final param in event.parameters) {
        if (param.description != null) {
          buffer.writeln(
            '  /// - `${param.name}`: ${param.type}${param.isNullable ? '?' : ''} - ${param.description}',
          );
        } else {
          buffer.writeln(
            '  /// - `${param.name}`: ${param.type}${param.isNullable ? '?' : ''}',
          );
        }
      }
    }

    // Method signature
    buffer.write('  void $methodName(');

    if (event.parameters.isNotEmpty) {
      buffer.writeln('{');
      for (final param in event.parameters) {
        final dartType = DartTypeMapper.toDartType(param.type);
        final nullableType = param.isNullable ? '$dartType?' : dartType;
        final required = param.isNullable ? '' : 'required ';
        final camelParam = _toCamelCase(param.codeName);
        buffer.writeln('    $required$nullableType $camelParam,');
      }
      buffer.writeln('  }) {');
      buffer.writeln();

      for (final param in event.parameters) {
        final allowedValues = param.allowedValues;
        if (allowedValues != null && allowedValues.isNotEmpty) {
          final camelParam = _toCamelCase(param.codeName);
          final constName =
              'allowed${StringUtils.capitalizePascal(camelParam)}Values';
          final encodedValues = allowedValues
              .map((value) => '\'${_escapeSingleQuoted(value)}\'')
              .join(', ');
          final joinedValues = allowedValues.join(', ');

          buffer.write(_generateAllowedValuesCheck(
            camelParam: camelParam,
            constName: constName,
            encodedValues: encodedValues,
            joinedValues: joinedValues,
            isNullable: param.isNullable,
          ));
        }
      }
    } else {
      buffer.writeln(') {');
    }

    // Method body
    final eventName =
        EventNaming.resolveEventName(domainName, event, config.naming);
    // Replace parameter placeholders like {screen_name} with Dart-style
    // string interpolation using the generated camelCase parameter name.
    final interpolatedEventName = _replacePlaceholdersWithInterpolation(
      eventName,
      event.parameters,
    );
    buffer.writeln('    logger.logEvent(');
    buffer.writeln('      name: "$interpolatedEventName",');

    if (event.parameters.isNotEmpty || includeDescription) {
      buffer.writeln('      parameters: <String, Object?>{');

      // Always include the description at the beginning when enabled.
      if (includeDescription) {
        buffer.writeln(
          "        'description': '${_escapeSingleQuoted(event.description)}',",
        );
      }
      for (final param in event.parameters) {
        final camelParam = _toCamelCase(param.codeName);
        if (param.isNullable) {
          buffer.writeln(
            '        if ($camelParam != null) "${param.name}": $camelParam,',
          );
        } else {
          buffer.writeln('        "${param.name}": $camelParam,');
        }
      }
      buffer.writeln('      },');
    } else {
      buffer.writeln('      parameters: const {},');
    }

    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    return buffer.toString();
  }

  /// Helper to generate allowed-values validation snippet for a parameter.
  String _generateAllowedValuesCheck({
    required String camelParam,
    required String constName,
    required String encodedValues,
    required String joinedValues,
    required bool isNullable,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('    const $constName = <String>{$encodedValues};');

    final condition = isNullable
        ? 'if ($camelParam != null && !$constName.contains($camelParam)) {'
        : 'if (!$constName.contains($camelParam)) {';

    buffer.writeln('    $condition');
    buffer.writeln('      throw ArgumentError.value(');
    buffer.writeln('        $camelParam,');
    buffer.writeln("        '$camelParam',");
    buffer.writeln("        'must be one of $joinedValues',");
    buffer.writeln('      );');
    buffer.writeln('    }');
    return buffer.toString();
  }

  String _buildDeprecationMessage(AnalyticsEvent event) {
    if (event.replacement == null || event.replacement!.isEmpty) {
      return 'This analytics event is deprecated.';
    }

    final methodName =
        EventNaming.buildLoggerMethodNameFromReplacement(event.replacement!);
    if (methodName != null) {
      return 'Use $methodName instead.';
    }

    return 'Use ${event.replacement} instead.';
  }

  /// Converts snake_case or kebab-case to camelCase
  String _toCamelCase(String text) {
    return StringUtils.toCamelCase(text);
  }

  String _escapeSingleQuoted(String value) {
    return value.replaceAll('\\', '\\\\').replaceAll("'", "\\'");
  }

  /// Converts placeholders in an event name from the analytics config
  /// (e.g. "Screen: {screen_name}") to Dart string interpolation using the
  /// generated camelCase parameter names (e.g. "Screen: ${screenName}").
  String _replacePlaceholdersWithInterpolation(
    String eventName,
    List<AnalyticsParameter> parameters,
  ) {
    final placeholder = RegExp(r"\{([^}]+)\}");

    return eventName.replaceAllMapped(placeholder, (match) {
      final key = match.group(1)!;
      final found = parameters.where((p) => p.name == key).toList();
      if (found.isEmpty) return match.group(0)!;

      final camel = _toCamelCase(found.first.name);
      return '\${$camel}';
    });
  }

  /// Generates Analytics singleton class with all domain mixins
  Future<void> _generateAnalyticsClass(
    Map<String, AnalyticsDomain> domains,
  ) async {
    final buffer = StringBuffer();

    // File header
    buffer.writeln("import 'package:analytics_gen/analytics_gen.dart';");
    buffer.writeln();
    buffer.writeln("import 'generated_events.dart';");
    buffer.writeln();

    // Class documentation
    buffer.writeln('/// Main Analytics singleton class.');
    buffer.writeln('///');
    buffer.writeln('/// Automatically generated with all domain mixins.');
    buffer.writeln(
        '/// Initialize once at app startup, then use throughout your app.');
    buffer.writeln('///');
    buffer.writeln('/// Example:');
    buffer.writeln('/// ```dart');
    buffer.writeln('/// Analytics.initialize(YourAnalyticsService());');
    buffer.writeln('/// Analytics.instance.logAuthLogin(method: "email");');
    buffer.writeln('/// ```');

    // Generate mixin list
    final sortedDomains = domains.keys.toList()..sort();
    final mixins = sortedDomains
        .map((d) => 'Analytics${StringUtils.capitalizePascal(d)}')
        .toList();

    // Class declaration
    buffer.write('final class Analytics extends AnalyticsBase');
    buffer.write(buildAnalyticsMixinClause(mixins));

    buffer.writeln('{');
    if (config.generatePlan) {
      buffer.write(_generateAnalyticsPlanField(domains));
      buffer.writeln();
    }

    // Singleton implementation
    buffer
        .writeln('  static final Analytics _instance = Analytics._internal();');
    buffer.writeln('  Analytics._internal();');
    buffer.writeln();
    buffer.writeln('  /// Access the singleton instance');
    buffer.writeln('  static Analytics get instance => _instance;');
    buffer.writeln();
    buffer.writeln('  IAnalytics? _analytics;');
    buffer.writeln(
        '  AnalyticsCapabilityResolver _capabilities = const NullCapabilityResolver();');
    buffer.writeln();
    buffer.writeln('  /// Whether analytics has been initialized');
    buffer.writeln('  bool get isInitialized => _analytics != null;');
    buffer.writeln();
    buffer.writeln('  /// Initialize analytics with your provider');
    buffer.writeln('  ///');
    buffer.writeln(
        '  /// Call this once at app startup before using any analytics methods.');
    buffer.writeln('  static void initialize(IAnalytics analytics) {');
    buffer.writeln('    _instance._analytics = analytics;');
    buffer.writeln(
        '    _instance._capabilities = analyticsCapabilitiesFor(analytics);');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln(
      '  IAnalytics get logger => ensureAnalyticsInitialized(_analytics);',
    );
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln(
        '  AnalyticsCapabilityResolver get capabilities => _capabilities;');
    buffer.writeln('}');
    buffer.writeln();

    // Write to file
    final analyticsPath = path.join(
      projectRoot,
      'lib',
      config.outputPath,
      'analytics.dart',
    );
    await _writeFileIfContentChanged(analyticsPath, buffer.toString());

    log?.call('✓ Generated Analytics class at: $analyticsPath');
  }

  String _generateAnalyticsPlanField(Map<String, AnalyticsDomain> domains) {
    final buffer = StringBuffer();
    buffer.writeln('  /// Runtime view of the generated tracking plan.');
    buffer.writeln(
      '  static const List<AnalyticsDomain> plan = <AnalyticsDomain>[',
    );

    final sortedDomains = domains.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in sortedDomains) {
      buffer.write(_analyticsDomainPlanEntry(entry.value));
    }

    buffer.writeln('  ];');
    return buffer.toString();
  }

  String _analyticsDomainPlanEntry(AnalyticsDomain domain) {
    final buffer = StringBuffer();
    buffer.writeln('    AnalyticsDomain(');
    buffer.writeln("      name: '${_escapeSingleQuoted(domain.name)}',");
    buffer.writeln('      events: <AnalyticsEvent>[');

    for (final event in domain.events) {
      buffer.write(_analyticsEventPlanEntry(event));
    }

    buffer.writeln('      ],');
    buffer.writeln('    ),');
    return buffer.toString();
  }

  String _analyticsEventPlanEntry(AnalyticsEvent event) {
    final buffer = StringBuffer();
    buffer.writeln('        AnalyticsEvent(');
    buffer.writeln("          name: '${_escapeSingleQuoted(event.name)}',");
    buffer.writeln(
      "          description: '${_escapeSingleQuoted(event.description)}',",
    );
    if (event.identifier != null) {
      buffer.writeln(
        "          identifier: '${_escapeSingleQuoted(event.identifier!)}',",
      );
    }
    if (event.customEventName != null) {
      buffer.writeln(
        "          customEventName: '${_escapeSingleQuoted(event.customEventName!)}',",
      );
    }
    buffer.writeln('          deprecated: ${event.deprecated},');
    if (event.replacement != null) {
      buffer.writeln(
        "          replacement: '${_escapeSingleQuoted(event.replacement!)}',",
      );
    }
    buffer.writeln('          parameters: <AnalyticsParameter>[');

    for (final param in event.parameters) {
      buffer.write(_analyticsParameterPlanEntry(param));
    }

    buffer.writeln('          ],');
    buffer.writeln('        ),');
    return buffer.toString();
  }

  /// Writes a file only if its contents differ from the existing file.
  ///
  /// This avoids touching modified times and prevents unnecessary git
  /// diffs when regenerating code with no changes.
  Future<void> _writeFileIfContentChanged(
      String filePath, String contents) async {
    await writeFileIfContentChanged(filePath, contents);
  }

  String _analyticsParameterPlanEntry(AnalyticsParameter param) {
    final buffer = StringBuffer();
    buffer.writeln('            AnalyticsParameter(');
    buffer.writeln("              name: '${_escapeSingleQuoted(param.name)}',");
    if (param.codeName != param.name) {
      buffer.writeln(
        "              codeName: '${_escapeSingleQuoted(param.codeName)}',",
      );
    }
    buffer.writeln("              type: '${_escapeSingleQuoted(param.type)}',");
    buffer.writeln('              isNullable: ${param.isNullable},');
    if (param.description != null) {
      buffer.writeln(
        "              description: '${_escapeSingleQuoted(param.description!)}',",
      );
    }
    if (param.allowedValues != null && param.allowedValues!.isNotEmpty) {
      buffer.writeln('              allowedValues: <String>[');
      for (final value in param.allowedValues!) {
        buffer.writeln(
          "                '${_escapeSingleQuoted(value)}',",
        );
      }
      buffer.writeln('              ],');
    }
    buffer.writeln('            ),');
    return buffer.toString();
  }

  /// Removes stale generated files so deleted domains do not linger.
  Future<void> _prepareOutputDirectories(
    String outputDir,
    String eventsDir,
  ) async {
    final outputDirectory = Directory(outputDir);
    if (!outputDirectory.existsSync()) {
      await outputDirectory.create(recursive: true);
    }

    final eventsDirectory = Directory(eventsDir);
    if (!eventsDirectory.existsSync()) {
      await eventsDirectory.create(recursive: true);
    }
  }

  Future<void> _cleanStaleFiles(
    String eventsDir,
    Set<String> generatedFiles,
  ) async {
    final dir = Directory(eventsDir);
    if (!dir.existsSync()) return;

    await for (final entity in dir.list()) {
      if (entity is File && !generatedFiles.contains(entity.path)) {
        await entity.delete();
      }
    }
  }
}

String buildAnalyticsMixinClause(List<String> mixins) {
  if (mixins.isEmpty) {
    return '\n';
  }

  if (mixins.length > 3) {
    final buffer = StringBuffer();
    buffer.writeln(' with');
    for (var i = 0; i < mixins.length; i++) {
      final comma = i < mixins.length - 1 ? ',' : '';
      buffer.writeln('    ${mixins[i]}$comma');
    }
    return buffer.toString();
  }

  return ' with ${mixins.join(', ')}\n';
}
