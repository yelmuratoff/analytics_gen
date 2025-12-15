/// Defines how analytics domains, events, and parameters are named.
///
/// The default strategy enforces snake_case domains/parameters and uses a
/// `<domain>: <event>` template when no custom `event_name` is provided.
final class NamingStrategy {
  /// Creates a new naming strategy.
  const NamingStrategy({
    this.enforceSnakeCaseDomains = true,
    this.enforceSnakeCaseParameters = true,
    this.eventNameTemplate = '{domain}: {event}',
    String? identifierTemplate,
    Map<String, String>? domainAliases,
    this.convention = EventNamingConvention.snakeCase,
  })  : identifierTemplate = identifierTemplate ?? '{domain}: {event}',
        domainAliases = domainAliases ?? const {};

  /// Creates a naming strategy from a YAML map.
  factory NamingStrategy.fromYaml(Map<dynamic, dynamic>? yaml) {
    if (yaml == null) {
      return const NamingStrategy();
    }

    final aliasesRaw = yaml['domain_aliases'];
    final aliases = <String, String>{};
    if (aliasesRaw is Map) {
      for (final entry in aliasesRaw.entries) {
        aliases[entry.key.toString()] = entry.value.toString();
      }
    }

    final conventionStr = yaml['casing'] as String?;
    final convention = switch (conventionStr) {
      'snake_case' => EventNamingConvention.snakeCase,
      'title_case' => EventNamingConvention.titleCase,
      'original' => EventNamingConvention.original,
      _ => EventNamingConvention.snakeCase,
    };

    return NamingStrategy(
      enforceSnakeCaseDomains:
          yaml['enforce_snake_case_domains'] as bool? ?? true,
      enforceSnakeCaseParameters:
          yaml['enforce_snake_case_parameters'] as bool? ?? true,
      eventNameTemplate:
          yaml['event_name_template'] as String? ?? '{domain}: {event}',
      identifierTemplate:
          yaml['identifier_template'] as String? ?? '{domain}: {event}',
      domainAliases: aliases,
      convention: convention,
    );
  }
  static final _snakeCaseDomain = RegExp(r'^[a-z0-9_]+$');
  static final _snakeCaseParam = RegExp(r'^[a-z][a-z0-9_]*$');

  /// Whether to enforce snake_case validation on domain keys.
  final bool enforceSnakeCaseDomains;

  /// Whether to enforce snake_case validation on parameter identifiers.
  final bool enforceSnakeCaseParameters;

  /// Template used when resolving the loggable event name.
  ///
  /// Supports `{domain}`, `{domain_alias}`, and `{event}` placeholders.
  final String eventNameTemplate;

  /// Template used when resolving the canonical identifier for uniqueness.
  ///
  /// Supports the same placeholders as [eventNameTemplate].
  final String identifierTemplate;

  /// Optional map of domain aliases used when rendering templates.
  ///
  /// When a domain is present, `{domain_alias}` resolves to the mapped value.
  final Map<String, String> domainAliases;

  /// The naming convention to apply to the generated event name.
  final EventNamingConvention convention;

  /// Returns `true` when [domain] satisfies the configured validation.
  bool isValidDomain(String domain) {
    if (!enforceSnakeCaseDomains) return true;
    return _snakeCaseDomain.hasMatch(domain);
  }

  /// Returns `true` when [parameter] satisfies the configured validation.
  bool isValidParameterIdentifier(String parameter) {
    if (!enforceSnakeCaseParameters) return true;
    return _snakeCaseParam.hasMatch(parameter);
  }

  /// Renders the configured event-name template and applies the naming convention.
  String renderEventName({
    required String domain,
    required String event,
  }) {
    final rawName =
        _renderTemplate(eventNameTemplate, domain: domain, event: event);
    return switch (convention) {
      EventNamingConvention.snakeCase => _toSnakeCase(rawName),
      EventNamingConvention.titleCase => _toTitleCase(rawName),
      EventNamingConvention.original => rawName,
    };
  }

  /// Renders the configured identifier template.
  String renderIdentifier({
    required String domain,
    required String event,
  }) {
    return _renderTemplate(identifierTemplate, domain: domain, event: event);
  }

  String _renderTemplate(
    String template, {
    required String domain,
    required String event,
  }) {
    final alias = domainAliases[domain] ?? domain;
    return template
        .replaceAll('{domain}', domain)
        .replaceAll('{domain_alias}', alias)
        .replaceAll('{event}', event);
  }

  static String _toSnakeCase(String text) {
    return text
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '')
        .toLowerCase();
  }

  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    final words =
        text.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ').trim().split(' ');
    // Handle split returning empty strings for consecutive delimiters if regex was different,
    // but replacing block of non-alphanum with single space prevents that mostly.
    return words.where((w) => w.isNotEmpty).map((word) {
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

/// Supported naming conventions for generated analytics events.
enum EventNamingConvention {
  /// "Example Event" -> "example_event"
  /// Useful for SQL/DB exports (e.g. BigQuery).
  snakeCase,

  /// "example_event" -> "Example Event"
  /// Useful for non-technical dashboards (e.g. Mixpanel, Amplitude).
  titleCase,

  /// Preserves the original naming from the YAML/Template.
  /// Example: "domain: event" stays "domain: event".
  original,
}
