#!/usr/bin/env dart

// ignore: dangling_library_doc_comments
/// Generates Markdown documentation from JSON schemas.
/// Run: dart run scripts/generate_schema_docs.dart
///
/// Source: schema/*.schema.json → Output: doc/SCHEMA_REFERENCE.md
import 'dart:convert';
import 'dart:io';

void main() {
  final schemaDir = Directory('schema');
  if (!schemaDir.existsSync()) {
    stderr
        .writeln('Error: schema/ directory not found. Run from project root.');
    exit(1);
  }

  final buf = StringBuffer();
  buf.writeln('# Schema Reference');
  buf.writeln();
  buf.writeln(
      '> Auto-generated from `schema/*.json` — do not edit manually.  ');
  buf.writeln('> Run: `dart run scripts/generate_schema_docs.dart`');
  buf.writeln();
  buf.writeln('---');
  buf.writeln();

  // Config
  final config = _loadSchema(schemaDir, 'analytics_gen.schema.json');
  final root = config['properties']['analytics_gen'] as Map<String, dynamic>;
  buf.writeln('## Configuration (`analytics_gen.yaml`)');
  buf.writeln();
  buf.writeln(config['description'] ?? '');
  buf.writeln();
  _documentObject(buf, root, depth: 3);

  // Events
  final events = _loadSchema(schemaDir, 'events.schema.json');
  buf.writeln('---');
  buf.writeln();
  buf.writeln('## Events');
  buf.writeln();
  buf.writeln(events['description'] ?? '');
  buf.writeln();
  final eventDef = (events[r'$defs'] as Map<String, dynamic>)['event']
      as Map<String, dynamic>;
  buf.writeln('### Event Properties');
  buf.writeln();
  _documentProperties(buf, eventDef['properties'] as Map<String, dynamic>);

  // Parameters
  final param = _loadSchema(schemaDir, 'parameter.schema.json');
  buf.writeln('---');
  buf.writeln();
  buf.writeln('## Parameter');
  buf.writeln();
  buf.writeln(param['description'] ?? '');
  buf.writeln();
  _documentProperties(buf, param['properties'] as Map<String, dynamic>);

  // Context
  final context = _loadSchema(schemaDir, 'context.schema.json');
  buf.writeln('---');
  buf.writeln();
  buf.writeln('## Context');
  buf.writeln();
  buf.writeln(context['description'] ?? '');
  buf.writeln();
  final paramProps = param['properties'] as Map<String, dynamic>;
  final opsItems = (paramProps['operations'] as Map<String, dynamic>?)?['items'] as Map<String, dynamic>?;
  final opsEnum = (opsItems?['enum'] as List?)?.map((e) => '`$e`').join(', ') ?? '';
  buf.writeln(
      'Context properties use the same fields as [Parameter](#parameter), ');
  buf.writeln(
      'plus the `operations` field ($opsEnum).');
  buf.writeln();

  // Shared Parameters
  final shared = _loadSchema(schemaDir, 'shared_parameters.schema.json');
  buf.writeln('---');
  buf.writeln();
  buf.writeln('## Shared Parameters');
  buf.writeln();
  buf.writeln(shared['description'] ?? '');
  buf.writeln();
  buf.writeln(
      'Shared parameters use the same fields as [Parameter](#parameter). ');
  buf.writeln(
      'Reference them in events with a null value: `session_id:` (no value).');
  buf.writeln();

  File('doc/SCHEMA_REFERENCE.md').writeAsStringSync(buf.toString());
  stdout.writeln('✓ Generated docs → doc/SCHEMA_REFERENCE.md');
}

Map<String, dynamic> _loadSchema(Directory dir, String name) {
  return jsonDecode(File('${dir.path}/$name').readAsStringSync())
      as Map<String, dynamic>;
}

void _documentObject(StringBuffer buf, Map<String, dynamic> schema,
    {int depth = 3}) {
  final props = schema['properties'] as Map<String, dynamic>? ?? {};
  for (final entry in props.entries) {
    final prop = entry.value as Map<String, dynamic>;
    if (prop.containsKey('x-alias-for')) continue;

    if (prop['type'] == 'object' && prop.containsKey('properties')) {
      final title = prop['title'] as String? ?? entry.key;
      final desc = prop['description'] as String? ?? '';
      buf.writeln('${'#' * depth} $title');
      buf.writeln();
      if (desc.isNotEmpty) buf.writeln(desc);
      buf.writeln();
      _documentProperties(buf, prop['properties'] as Map<String, dynamic>);
    }
  }
}

void _documentProperties(StringBuffer buf, Map<String, dynamic> props) {
  buf.writeln('| Field | Type | Default | Description |');
  buf.writeln('|-------|------|---------|-------------|');

  for (final entry in props.entries) {
    final prop = entry.value as Map<String, dynamic>;
    if (prop.containsKey('x-alias-for')) continue;

    final type = _formatType(prop);
    final defaultVal = prop['default'];
    final desc = (prop['description'] as String? ?? '')
        .replaceAll('|', '\\|')
        .replaceAll('\n', ' ');
    final defaultStr = defaultVal != null ? '`${jsonEncode(defaultVal)}`' : '—';

    buf.writeln('| `${entry.key}` | $type | $defaultStr | $desc |');
  }
  buf.writeln();
}

String _formatType(Map<String, dynamic> prop) {
  final type = prop['type'] as String? ?? '—';
  final enumVals = prop['enum'] as List?;
  if (enumVals != null) return enumVals.map((e) => '`$e`').join(' \\| ');
  return '`$type`';
}
