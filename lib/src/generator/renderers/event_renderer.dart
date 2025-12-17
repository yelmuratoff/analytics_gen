import 'package:analytics_gen/src/models/analytics_domain.dart';

import '../../config/analytics_config.dart';
import '../../models/analytics_event.dart';
import '../../util/event_naming.dart';
import '../../util/string_utils.dart';
import '../utils/import_manager.dart';
import 'base_renderer.dart';
import 'enum_renderer.dart';
import 'sub_renderers/documentation_renderer.dart';
import 'sub_renderers/event_body_renderer.dart';
import 'sub_renderers/method_signature_renderer.dart';

/// Renders analytics event domain files.
class EventRenderer extends BaseRenderer {
  /// Creates a new event renderer.
  EventRenderer(
    this.config, {
    this.enumRenderer = const EnumRenderer(),
    this.docRenderer = const DocumentationRenderer(),
    this.sigRenderer = const MethodSignatureRenderer(),
    EventBodyRenderer? bodyRenderer,
  }) : bodyRenderer = bodyRenderer ?? EventBodyRenderer(config);

  /// The analytics configuration.
  final AnalyticsConfig config;

  /// The enum renderer.
  final EnumRenderer enumRenderer;

  /// The documentation renderer.
  final DocumentationRenderer docRenderer;

  /// The method signature renderer.
  final MethodSignatureRenderer sigRenderer;

  /// The event body renderer.
  final EventBodyRenderer bodyRenderer;

  /// Renders a domain file with event methods.
  String renderDomainFile(
    String domainName,
    AnalyticsDomain domain,
    Map<String, AnalyticsDomain> allDomains,
  ) {
    final buffer = StringBuffer();

    // Collect imports from parameters
    final importManager = ImportManager();
    importManager.add(AnalyticsConfig.kPackageImport);
    importManager.addAll(config.inputs.imports);

    for (final event in domain.events) {
      for (final param in event.parameters) {
        if (param.dartImport != null) {
          importManager.add(param.dartImport!);
        }
      }
    }

    // File header
    buffer.write(renderFileHeader());

    // Write imports
    buffer.write(renderImports(importManager.getSortedImports()));

    // Generate Enums
    buffer.write(enumRenderer.renderEnums(domainName, domain));

    // Generate mixin
    buffer.write(renderDomainMixin(domainName, domain, allDomains));

    return buffer.toString();
  }

  /// Renders a domain mixin with event methods.
  String renderDomainMixin(
    String domainName,
    AnalyticsDomain domain,
    Map<String, AnalyticsDomain> allDomains,
  ) {
    final buffer = StringBuffer();
    final className = 'Analytics${StringUtils.capitalizePascal(domainName)}';

    // Collect all regex patterns from events for static caching
    final regexPatterns = _collectRegexPatterns(domain);

    buffer.writeln('/// Generated mixin for $domainName analytics events');
    buffer.writeln('mixin $className on AnalyticsBase {');

    // Generate static cached RegExp instances at mixin level
    if (regexPatterns.isNotEmpty) {
      buffer
          .writeln('  // Cached regex patterns for validation (compiled once)');
      for (final entry in regexPatterns.entries) {
        buffer.writeln(
            "  static final ${entry.key} = RegExp(r'${entry.value}');");
      }
      buffer.writeln();
    }

    for (final event in domain.events) {
      buffer.write(
          _renderEventMethod(domainName, event, allDomains, regexPatterns));
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  /// Collects all regex patterns from domain events.
  /// Returns a map of unique field name -> pattern.
  Map<String, String> _collectRegexPatterns(AnalyticsDomain domain) {
    final patterns = <String, String>{};
    for (final event in domain.events) {
      for (final param in event.parameters) {
        if (param.regex != null && param.dartType == null) {
          final fieldName = '_${StringUtils.toCamelCase(param.codeName)}Regex';
          // Use first occurrence if same param name has different patterns
          patterns.putIfAbsent(fieldName, () => param.regex!);
        }
      }
    }
    return patterns;
  }

  String _renderEventMethod(
    String domainName,
    AnalyticsEvent event,
    Map<String, AnalyticsDomain> allDomains,
    Map<String, String> regexPatterns,
  ) {
    final buffer = StringBuffer();
    final methodName = EventNaming.buildLoggerMethodName(
      domainName,
      event.name,
    );

    // Deprecation annotation
    if (event.deprecated) {
      final message = _buildDeprecationMessage(event);
      buffer.writeln("  @Deprecated('$message')");
    } else {
      if (event.interpolatedName != null) {
        buffer.writeln(
            "  @Deprecated('This event uses string interpolation in its name, which causes high cardinality. Use parameters instead.')");
      }
    }

    // Documentation
    buffer.write(docRenderer.renderEventDocs(
      domainName,
      event,
      indent: 1,
    ));

    // Method signature
    buffer.write('  void $methodName(');
    buffer.write(sigRenderer.renderEventArguments(
      domainName,
      event,
      indent: 2,
    ));
    buffer.writeln(') {');
    buffer.writeln();

    // Body
    buffer.write(bodyRenderer.renderBody(
      domainName,
      event,
      allDomains,
      indent: 2,
      regexPatterns: regexPatterns,
    ));

    buffer.writeln('  }');
    buffer.writeln();

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
}
