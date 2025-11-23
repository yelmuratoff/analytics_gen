import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:analytics_gen/src/util/schema_comparator.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaComparator', () {
    final comparator = SchemaComparator();

    test('detects added domain', () {
      final previous = <String, AnalyticsDomain>{};
      final current = {
        'auth': AnalyticsDomain(name: 'auth', events: []),
      };

      final changes = comparator.compare(current, previous);
      expect(changes, hasLength(1));
      expect(changes.first.type, SchemaChangeType.added);
      expect(changes.first.path, 'auth');
    });

    test('detects removed domain (breaking)', () {
      final previous = {
        'auth': AnalyticsDomain(name: 'auth', events: []),
      };
      final current = <String, AnalyticsDomain>{};

      final changes = comparator.compare(current, previous);
      expect(changes, hasLength(1));
      expect(changes.first.type, SchemaChangeType.removed);
      expect(changes.first.isBreaking, isTrue);
    });

    test('detects added event', () {
      final previous = {
        'auth': AnalyticsDomain(name: 'auth', events: []),
      };
      final current = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [],
            ),
          ],
        ),
      };

      final changes = comparator.compare(current, previous);
      expect(changes, hasLength(1));
      expect(changes.first.type, SchemaChangeType.added);
      expect(changes.first.path, 'auth.login');
    });

    test('detects removed event (breaking)', () {
      final previous = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [],
            ),
          ],
        ),
      };
      final current = {
        'auth': AnalyticsDomain(name: 'auth', events: []),
      };

      final changes = comparator.compare(current, previous);
      expect(changes, hasLength(1));
      expect(changes.first.type, SchemaChangeType.removed);
      expect(changes.first.isBreaking, isTrue);
    });

    test('detects parameter type change (breaking)', () {
      final previous = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [
                AnalyticsParameter(
                  name: 'method',
                  type: 'string',
                  isNullable: false,
                ),
              ],
            ),
          ],
        ),
      };
      final current = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [
                AnalyticsParameter(
                  name: 'method',
                  type: 'int', // Changed from string
                  isNullable: false,
                ),
              ],
            ),
          ],
        ),
      };

      final changes = comparator.compare(current, previous);
      expect(changes, hasLength(1));
      expect(changes.first.type, SchemaChangeType.modified);
      expect(changes.first.isBreaking, isTrue);
      expect(changes.first.description, contains('Type changed'));
    });

    test(
        'detects parameter nullability change (breaking if became non-nullable)',
        () {
      final previous = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [
                AnalyticsParameter(
                  name: 'method',
                  type: 'string',
                  isNullable: true,
                ),
              ],
            ),
          ],
        ),
      };
      final current = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [
                AnalyticsParameter(
                  name: 'method',
                  type: 'string',
                  isNullable: false, // Changed to non-nullable
                ),
              ],
            ),
          ],
        ),
      };

      final changes = comparator.compare(current, previous);
      expect(changes, hasLength(1));
      expect(changes.first.isBreaking, isTrue);
    });

    test(
        'detects parameter nullability change (non-breaking if became nullable)',
        () {
      final previous = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [
                AnalyticsParameter(
                  name: 'method',
                  type: 'string',
                  isNullable: false,
                ),
              ],
            ),
          ],
        ),
      };
      final current = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [
                AnalyticsParameter(
                  name: 'method',
                  type: 'string',
                  isNullable: true, // Changed to nullable
                ),
              ],
            ),
          ],
        ),
      };

      final changes = comparator.compare(current, previous);
      expect(changes, hasLength(1));
      expect(changes.first.isBreaking, isFalse);
    });

    test('loads schema from JSON', () {
      const json = '''
      {
        "domains": [
          {
            "name": "auth",
            "events": [
              {
                "name": "login",
                "description": "Login",
                "parameters": [
                  {
                    "name": "method",
                    "type": "string",
                    "nullable": false,
                    "added_in": "1.0.0"
                  }
                ],
                "added_in": "1.0.0"
              }
            ]
          }
        ]
      }
      ''';

      final domains = SchemaComparator.loadSchemaFromJson(json);
      expect(domains, contains('auth'));
      final auth = domains['auth']!;
      expect(auth.events, hasLength(1));
      final login = auth.events.first;
      expect(login.name, 'login');
      expect(login.addedIn, '1.0.0');
      expect(login.parameters, hasLength(1));
      expect(login.parameters.first.addedIn, '1.0.0');
    });
    test('SchemaChange.toString formats correctly', () {
      const change = SchemaChange(
        type: SchemaChangeType.added,
        description: 'Test description',
        path: 'test.path',
        isBreaking: true,
      );
      expect(
        change.toString(),
        '[ADDED] test.path: Test description (BREAKING)',
      );
    });

    test('detects event deprecation change', () {
      final previous = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              deprecated: false,
              parameters: [],
            ),
          ],
        ),
      };
      final current = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              deprecated: true,
              parameters: [],
            ),
          ],
        ),
      };

      final changes = comparator.compare(current, previous);
      expect(changes, hasLength(1));
      expect(changes.first.type, SchemaChangeType.modified);
      expect(changes.first.description, 'Event was deprecated.');
    });

    test('detects dual-write removed (breaking)', () {
      final previous = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              dualWriteTo: ['firebase'],
              parameters: [],
            ),
          ],
        ),
      };
      final current = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [],
            ),
          ],
        ),
      };

      final changes = comparator.compare(current, previous);
      expect(changes, hasLength(1));
      expect(changes.first.isBreaking, isTrue);
      expect(changes.first.description, contains('Dual-write targets removed'));
    });

    test('detects dual-write added (non-breaking)', () {
      final previous = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [],
            ),
          ],
        ),
      };
      final current = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              dualWriteTo: ['firebase'],
              parameters: [],
            ),
          ],
        ),
      };

      final changes = comparator.compare(current, previous);
      expect(changes, hasLength(1));
      expect(changes.first.isBreaking, isFalse);
      expect(changes.first.description, contains('Dual-write targets added'));
    });

    test('detects parameter removed (breaking)', () {
      final previous = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [
                AnalyticsParameter(
                  name: 'method',
                  type: 'string',
                  isNullable: false,
                ),
              ],
            ),
          ],
        ),
      };
      final current = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [],
            ),
          ],
        ),
      };

      final changes = comparator.compare(current, previous);
      expect(changes, hasLength(1));
      expect(changes.first.type, SchemaChangeType.removed);
      expect(changes.first.isBreaking, isTrue);
      expect(changes.first.description,
          contains('Parameter "method" was removed'));
    });

    test('detects parameter added (breaking if required)', () {
      final previous = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [],
            ),
          ],
        ),
      };
      final current = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [
                AnalyticsParameter(
                  name: 'method',
                  type: 'string',
                  isNullable: false,
                ),
              ],
            ),
          ],
        ),
      };

      final changes = comparator.compare(current, previous);
      expect(changes, hasLength(1));
      expect(changes.first.type, SchemaChangeType.added);
      expect(changes.first.isBreaking, isTrue);
      expect(
          changes.first.description, contains('Parameter "method" was added'));
    });

    test('detects regex validation change (breaking)', () {
      final previous = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [
                AnalyticsParameter(
                  name: 'email',
                  type: 'string',
                  isNullable: false,
                  regex: r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ),
              ],
            ),
          ],
        ),
      };
      final current = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [
                AnalyticsParameter(
                  name: 'email',
                  type: 'string',
                  isNullable: false,
                  regex: r'^.+@.+$', // Changed regex
                ),
              ],
            ),
          ],
        ),
      };

      final changes = comparator.compare(current, previous);
      expect(changes, hasLength(1));
      expect(changes.first.type, SchemaChangeType.modified);
      expect(changes.first.isBreaking, isTrue);
      expect(changes.first.description, 'Regex validation changed.');
    });
  });
}
