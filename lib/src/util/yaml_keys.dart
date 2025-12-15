library;
// ignore_for_file: public_member_api_docs

/// Constants for YAML keys used in analytics configuration and event definitions.
final class YamlKeys {
  const YamlKeys._();

  // Root keys
  static const String analyticsGen = 'analytics_gen';

  // Section keys
  static const String inputs = 'inputs';
  static const String outputs = 'outputs';
  static const String targets = 'targets';
  static const String rules = 'rules';
  static const String naming = 'naming';

  // Input keys
  static const String events = 'events';
  static const String eventsPath = 'events_path';
  static const String sharedParameters = 'shared_parameters';
  static const String contexts = 'contexts';
  static const String imports = 'imports';

  // Output keys
  static const String dart = 'dart';
  static const String outputPath = 'output_path';
  static const String docs = 'docs';
  static const String docsPath = 'docs_path';
  static const String exports = 'exports';
  static const String exportsPath = 'exports_path';

  // Target keys
  static const String generateCsv = 'generate_csv';
  static const String generateJson = 'generate_json';
  static const String generateSql = 'generate_sql';
  static const String generateDocs = 'generate_docs';
  static const String generatePlan = 'generate_plan';
  static const String generateTestMatchers = 'generate_test_matchers';
  static const String csv = 'csv';
  static const String json = 'json';
  static const String sql = 'sql';
  static const String plan = 'plan';
  static const String testMatchers = 'test_matchers';

  // Rule keys
  static const String includeEventDescription = 'include_event_description';
  static const String strictEventNames = 'strict_event_names';
  static const String enforceCentrallyDefinedParameters =
      'enforce_centrally_defined_parameters';
  static const String preventEventParameterDuplicates =
      'prevent_event_parameter_duplicates';

  // Event keys
  static const String eventName = 'event_name';
  static const String description = 'description';
  static const String identifier = 'identifier';
  static const String deprecated = 'deprecated';
  static const String replacement = 'replacement';
  static const String addedIn = 'added_in';
  static const String deprecatedIn = 'deprecated_in';
  static const String dualWriteTo = 'dual_write_to';
  static const String meta = 'meta';
  static const String parameters = 'parameters';
  static const String sourcePath = 'source_path';
  static const String lineNumber = 'line_number';
}
