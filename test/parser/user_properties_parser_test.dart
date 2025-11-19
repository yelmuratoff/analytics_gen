import 'dart:io';

import 'package:analytics_gen/src/parser/yaml_parser.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory tempDir;
  late String eventsPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('analytics_gen_test_');
    eventsPath = tempDir.path;
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('parseUserProperties parses valid user_properties.yaml', () async {
    final file = File(path.join(eventsPath, 'user_properties.yaml'));
    file.writeAsStringSync('''
user_properties:
  user_role:
    type: String
    allowed_values: [admin, editor, viewer]
    description: The role of the user.
  is_premium:
    type: bool
    meta:
      pii: false
''');

    final parser = YamlParser(eventsPath: eventsPath);
    final properties = await parser.parseUserProperties();

    expect(properties, hasLength(2));
    
    final role = properties.firstWhere((p) => p.name == 'user_role');
    expect(role.type, 'String');
    expect(role.allowedValues, ['admin', 'editor', 'viewer']);
    expect(role.description, 'The role of the user.');

    final premium = properties.firstWhere((p) => p.name == 'is_premium');
    expect(premium.type, 'bool');
    expect(premium.meta, {'pii': false});
  });

  test('loadAnalyticsDomains ignores user_properties.yaml', () async {
    final propsFile = File(path.join(eventsPath, 'user_properties.yaml'));
    propsFile.writeAsStringSync('''
user_properties:
  foo: String
''');

    final domainFile = File(path.join(eventsPath, 'auth.yaml'));
    domainFile.writeAsStringSync('''
auth:
  login:
    description: User logged in
''');

    final parser = YamlParser(eventsPath: eventsPath);
    final domains = await parser.parseEvents();

    expect(domains.length, 1);
    expect(domains.keys.first, 'auth');
  });

  test('parseUserProperties returns empty list if file missing', () async {
    final parser = YamlParser(eventsPath: eventsPath);
    final properties = await parser.parseUserProperties();
    expect(properties, isEmpty);
  });
}
