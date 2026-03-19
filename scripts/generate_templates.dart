#!/usr/bin/env dart

// ignore: dangling_library_doc_comments
/// Generates YAML template files from JSON schemas.
/// Run: dart run scripts/generate_templates.dart
///
/// Source: schema/*.schema.json → Output: templates/*.yaml
import 'dart:convert';
import 'dart:io';

void main() {
  final schemaDir = Directory('schema');
  final outputDir = Directory('templates');

  if (!schemaDir.existsSync()) {
    stderr
        .writeln('Error: schema/ directory not found. Run from project root.');
    exit(1);
  }
  outputDir.createSync(recursive: true);

  _generateConfigTemplate(schemaDir, outputDir);
  _generateEventsTemplate(schemaDir, outputDir);
  _generateSharedParametersTemplate(schemaDir, outputDir);
  _generateContextTemplate(schemaDir, outputDir);

  stdout.writeln('✓ Generated templates → templates/');
}

Map<String, dynamic> _loadSchema(Directory dir, String name) {
  return jsonDecode(File('${dir.path}/$name').readAsStringSync())
      as Map<String, dynamic>;
}

// ── Config template ──

void _generateConfigTemplate(Directory schemaDir, Directory outputDir) {
  final schema = _loadSchema(schemaDir, 'analytics_gen.schema.json');
  final root = schema['properties']['analytics_gen'] as Map<String, dynamic>;
  final props = root['properties'] as Map<String, dynamic>;

  final buf = StringBuffer();
  buf.writeln('# analytics_gen.yaml');
  buf.writeln(
      '# Auto-generated from schema — run: dart run scripts/generate_templates.dart');
  buf.writeln();
  buf.writeln('analytics_gen:');

  for (final entry in props.entries) {
    final prop = entry.value as Map<String, dynamic>;
    if (prop.containsKey('x-alias-for')) continue;
    if (prop['type'] == 'object' && prop.containsKey('properties')) {
      _writeObjectSection(buf, entry.key, prop, indent: 2);
    }
  }

  File('${outputDir.path}/analytics_gen.yaml')
      .writeAsStringSync(buf.toString());
}

void _writeObjectSection(
    StringBuffer buf, String key, Map<String, dynamic> schema,
    {int indent = 0}) {
  final pad = ' ' * indent;
  final title = schema['title'] as String? ?? key;
  buf.writeln();
  buf.writeln('$pad# ── $title ──');
  buf.writeln('$pad$key:');

  final props = schema['properties'] as Map<String, dynamic>? ?? {};
  for (final entry in props.entries) {
    _writeField(buf, entry.key, entry.value as Map<String, dynamic>,
        indent: indent + 2);
  }
}

void _writeField(StringBuffer buf, String key, Map<String, dynamic> schema,
    {int indent = 0}) {
  final pad = ' ' * indent;
  final desc = schema['description'] as String?;
  final type = schema['type'] as String?;
  final defaultVal = schema['default'];
  final enumVals = schema['enum'] as List?;

  buf.writeln();
  if (desc != null) {
    for (final line in _wrapText(desc, 76 - indent)) {
      buf.writeln('$pad# $line');
    }
  }
  if (enumVals != null) buf.writeln('$pad# Options: ${enumVals.join(', ')}');

  if (defaultVal != null) {
    buf.writeln('$pad$key: ${_yamlValue(defaultVal)}');
  } else if (type == 'array') {
    buf.writeln('$pad$key: []');
  } else if (type == 'object') {
    buf.writeln('$pad$key: {}');
  } else if (type == 'boolean') {
    buf.writeln('$pad$key: false');
  } else {
    buf.writeln('$pad# $key:');
  }
}

// ── Events template ──

void _generateEventsTemplate(Directory schemaDir, Directory outputDir) {
  final schema = _loadSchema(schemaDir, 'events.schema.json');
  final eventDef = (schema[r'$defs'] as Map<String, dynamic>)['event']
      as Map<String, dynamic>;
  final eventProps = eventDef['properties'] as Map<String, dynamic>;
  final paramSchema = _loadSchema(schemaDir, 'parameter.schema.json');
  final paramProps = paramSchema['properties'] as Map<String, dynamic>;

  final buf = StringBuffer();
  buf.writeln('# events.yaml — Event definitions');
  buf.writeln(
      '# Auto-generated from schema — run: dart run scripts/generate_templates.dart');
  buf.writeln('#');
  buf.writeln('# Each root key is a domain. Events are grouped under domains.');
  buf.writeln(
      '# Parameters: inline type string, full object, or null (shared reference).');
  buf.writeln();

  // Compact reference
  buf.writeln('# ── Event fields ──');
  for (final e in eventProps.entries) {
    final d = (e.value as Map)['description'] as String? ?? '';
    final short = d.length > 80 ? '${d.substring(0, 77)}...' : d;
    buf.writeln('#   ${e.key}: $short');
  }
  buf.writeln('#');
  buf.writeln('# ── Parameter fields ──');
  for (final e in paramProps.entries) {
    final d = (e.value as Map)['description'] as String? ?? '';
    final short = d.length > 80 ? '${d.substring(0, 77)}...' : d;
    buf.writeln('#   ${e.key}: $short');
  }
  buf.writeln();

  // Rich examples
  buf.writeln('# ── Examples ──');
  buf.writeln();
  buf.writeln('auth:');
  buf.writeln('  # Simple event');
  buf.writeln('  user_login:');
  buf.writeln('    description: User successfully logged in.');
  buf.writeln('    parameters:');
  buf.writeln('      method:');
  buf.writeln('        type: string');
  buf.writeln('        allowed_values: [email, google, apple]');
  buf.writeln('      success: bool');
  buf.writeln();
  buf.writeln(
      '  # Shared parameter references (null = from shared_parameters file)');
  buf.writeln('  user_login_v2:');
  buf.writeln('    description: User logs in (v2 with shared params).');
  buf.writeln('    parameters:');
  buf.writeln('      session_id:     # ← shared reference');
  buf.writeln('      method: string  # ← inline');
  buf.writeln();
  buf.writeln('  # Deprecated event with replacement');
  buf.writeln('  user_login_legacy:');
  buf.writeln('    description: Old login event.');
  buf.writeln('    deprecated: true');
  buf.writeln('    replacement: user_login_v2');
  buf.writeln('    added_in: "1.0.0"');
  buf.writeln('    deprecated_in: "2.0.0"');
  buf.writeln('    parameters:');
  buf.writeln('      method: string');
  buf.writeln();
  buf.writeln('commerce:');
  buf.writeln('  # Event with advanced parameters');
  buf.writeln('  purchase:');
  buf.writeln('    description: User completed a purchase.');
  buf.writeln('    dual_write_to: [purchase_v2]');
  buf.writeln('    meta:');
  buf.writeln('      owner: commerce-team');
  buf.writeln('      jira: SHOP-456');
  buf.writeln('    parameters:');
  buf.writeln('      amount:');
  buf.writeln('        type: double');
  buf.writeln('        min: 0');
  buf.writeln('        description: Purchase amount in USD.');
  buf.writeln('      currency:');
  buf.writeln('        type: string');
  buf.writeln('        regex: "^[A-Z]{3}\$"');
  buf.writeln('        description: ISO 4217 currency code.');
  buf.writeln('      payment_method:');
  buf.writeln('        dart_type: PaymentMethod');
  buf.writeln('        import: package:my_app/models/payment.dart');
  buf.writeln('        description: Payment method enum.');

  File('${outputDir.path}/events.yaml').writeAsStringSync(buf.toString());
}

// ── Shared parameters template ──

void _generateSharedParametersTemplate(
    Directory schemaDir, Directory outputDir) {
  final paramSchema = _loadSchema(schemaDir, 'parameter.schema.json');
  final paramProps = paramSchema['properties'] as Map<String, dynamic>;

  final buf = StringBuffer();
  buf.writeln('# shared_parameters.yaml — Reusable parameters');
  buf.writeln(
      '# Auto-generated from schema — run: dart run scripts/generate_templates.dart');
  buf.writeln('#');
  buf.writeln('# Define once, reference in events with null value:');
  buf.writeln('#   parameters:');
  buf.writeln('#     session_id:   # ← pulls from shared');
  buf.writeln();

  // Compact reference
  buf.writeln('# ── Available fields ──');
  for (final e in paramProps.entries) {
    final d = (e.value as Map)['description'] as String? ?? '';
    final short = d.length > 70 ? '${d.substring(0, 67)}...' : d;
    buf.writeln('#   ${e.key}: $short');
  }
  buf.writeln();

  // Examples
  buf.writeln('parameters:');
  buf.writeln('  session_id:');
  buf.writeln('    type: string');
  buf.writeln('    description: Unique session identifier.');
  buf.writeln();
  buf.writeln('  platform:');
  buf.writeln('    type: string');
  buf.writeln('    description: User platform.');
  buf.writeln('    allowed_values: [ios, android, web]');
  buf.writeln();
  buf.writeln('  user_id:');
  buf.writeln('    type: string?');
  buf.writeln('    description: Authenticated user ID (nullable).');
  buf.writeln();
  buf.writeln('  app_version:');
  buf.writeln('    type: string');
  buf.writeln('    description: Current app version.');
  buf.writeln('    param_name: app_ver');
  buf.writeln('    regex: "^\\d+\\.\\d+\\.\\d+\$"');
  buf.writeln();
  buf.writeln('  screen_width:');
  buf.writeln('    type: int');
  buf.writeln('    description: Device screen width in pixels.');
  buf.writeln('    min: 0');
  buf.writeln('    max: 10000');
  buf.writeln();
  buf.writeln('  locale:');
  buf.writeln('    type: string');
  buf.writeln('    dart_type: Locale');
  buf.writeln('    import: dart:ui');
  buf.writeln('    description: User locale.');

  File('${outputDir.path}/shared_parameters.yaml')
      .writeAsStringSync(buf.toString());
}

// ── Context template ──

void _generateContextTemplate(Directory schemaDir, Directory outputDir) {
  final paramSchema = _loadSchema(schemaDir, 'parameter.schema.json');
  final paramProps = paramSchema['properties'] as Map<String, dynamic>;
  final opsEnum = ((paramProps['operations'] as Map<String, dynamic>)['items']
      as Map<String, dynamic>)['enum'] as List?;

  final buf = StringBuffer();
  buf.writeln(
      '# context.yaml — Context properties (user properties, session, etc.)');
  buf.writeln(
      '# Auto-generated from schema — run: dart run scripts/generate_templates.dart');
  buf.writeln('#');
  if (opsEnum != null) {
    buf.writeln('# Operations: ${opsEnum.join(', ')}');
  }
  buf.writeln(
      '# Root key = context name. Properties support all parameter fields + operations.');
  buf.writeln();

  buf.writeln('user_properties:');
  buf.writeln('  user_id:');
  buf.writeln('    type: string');
  buf.writeln('    description: Unique user identifier.');
  buf.writeln();
  buf.writeln('  user_role:');
  buf.writeln('    type: string');
  buf.writeln('    description: User role.');
  buf.writeln('    allowed_values: [admin, editor, viewer]');
  buf.writeln();
  buf.writeln('  is_premium:');
  buf.writeln('    type: bool');
  buf.writeln('    description: Premium subscription status.');
  buf.writeln();
  buf.writeln('  login_count:');
  buf.writeln('    type: int');
  buf.writeln('    description: Total logins.');
  buf.writeln('    operations: [set, increment]');
  buf.writeln();
  buf.writeln('  tags:');
  buf.writeln('    type: string');
  buf.writeln('    description: User tags for segmentation.');
  buf.writeln('    operations: [append, remove]');
  buf.writeln();
  buf.writeln('  lifetime_value:');
  buf.writeln('    type: double');
  buf.writeln('    description: Total revenue from user.');
  buf.writeln('    operations: [set, increment]');
  buf.writeln('    min: 0');

  File('${outputDir.path}/context.yaml').writeAsStringSync(buf.toString());
}

// ── Helpers ──

String _yamlValue(dynamic value) {
  if (value is String) return value;
  if (value is bool) return value.toString();
  if (value is num) return value.toString();
  if (value is List) {
    return value.isEmpty
        ? '[]'
        : '\n${value.map((e) => '      - $e').join('\n')}';
  }
  if (value is Map) return value.isEmpty ? '{}' : jsonEncode(value);
  return value.toString();
}

List<String> _wrapText(String text, int maxWidth) {
  final words = text.split(' ');
  final lines = <String>[];
  var current = '';
  for (final word in words) {
    if (current.isEmpty) {
      current = word;
    } else if (current.length + 1 + word.length <= maxWidth) {
      current += ' $word';
    } else {
      lines.add(current);
      current = word;
    }
  }
  if (current.isNotEmpty) lines.add(current);
  return lines;
}
