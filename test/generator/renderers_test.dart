import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/config/naming_strategy.dart';
import 'package:analytics_gen/src/generator/renderers/analytics_class_renderer.dart';
import 'package:analytics_gen/src/generator/renderers/context_renderer.dart';
import 'package:analytics_gen/src/generator/renderers/event_renderer.dart';
import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:test/test.dart';

void main() {
  group('EventRenderer', () {
    late AnalyticsConfig config;
    late EventRenderer renderer;

    setUp(() {
      config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'lib/analytics',
      );
      renderer = EventRenderer(config);
    });

    test('renders domain file with mixin and events', () {
      final event = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: [
          AnalyticsParameter(
            name: 'method',
            type: 'string',
            isNullable: false,
          ),
        ],
      );
      final domain = AnalyticsDomain(name: 'auth', events: [event]);
      final allDomains = {'auth': domain};

      final result = renderer.renderDomainFile('auth', domain, allDomains);

      expect(result, contains('mixin AnalyticsAuth on AnalyticsBase'));
      expect(result, contains('void logAuthLogin({'));
      expect(result, contains('required String method,'));
      expect(result, contains('logger.logEvent('));
      expect(result, contains('name: "auth_login",'));
    });

    test('renders deprecated event', () {
      final event = AnalyticsEvent(
        name: 'old_event',
        description: 'Old event',
        parameters: [],
        deprecated: true,
        replacement: 'legacy.new_event',
      );
      final domain = AnalyticsDomain(name: 'legacy', events: [event]);
      final allDomains = {'legacy': domain};

      final result = renderer.renderDomainFile('legacy', domain, allDomains);

      expect(
          result, contains('@Deprecated(\'Use logLegacyNewEvent instead.\')'));
      // The generated event includes an optional `parameters` named argument
      // (the default code generator adds event parameter maps to all events
      // so every event function has the same optional parameter signature).
      expect(result, contains('void logLegacyOldEvent({'));
    });

    test('renders event with allowed values', () {
      final event = AnalyticsEvent(
        name: 'filter',
        description: 'Filter items',
        parameters: [
          AnalyticsParameter(
            name: 'sort',
            type: 'string',
            isNullable: false,
            allowedValues: ['asc', 'desc'],
          ),
        ],
      );
      final domain = AnalyticsDomain(name: 'items', events: [event]);
      final allDomains = {'items': domain};

      final result = renderer.renderDomainFile('items', domain, allDomains);

      expect(result, contains('enum AnalyticsItemsFilterSortEnum {'));
      expect(result, contains("asc('asc'),"));
      expect(result, contains("desc('desc');"));
      expect(result, contains('required AnalyticsItemsFilterSortEnum sort,'));
      expect(result, contains('"sort": sort.value,'));
    });

    test('renders event with allowed values starting with numbers', () {
      final event = AnalyticsEvent(
        name: 'version',
        description: 'Version selection',
        parameters: [
          AnalyticsParameter(
            name: 'number',
            type: 'string',
            isNullable: false,
            allowedValues: ['123test', '456value', '789item'],
          ),
        ],
      );
      final domain = AnalyticsDomain(name: 'app', events: [event]);
      final allDomains = {'app': domain};

      final result = renderer.renderDomainFile('app', domain, allDomains);

      expect(result, contains('enum AnalyticsAppVersionNumberEnum {'));
      expect(result, contains("value123test('123test'),"));
      expect(result, contains("value456value('456value'),"));
      expect(result, contains("value789item('789item');"));
    });

    test('renders event with non-string parameter having allowed values', () {
      final event = AnalyticsEvent(
        name: 'select',
        description: 'Select option',
        parameters: [
          AnalyticsParameter(
            name: 'option',
            type: 'int',
            isNullable: false,
            allowedValues: [1, 2, 3],
          ),
        ],
      );
      final domain = AnalyticsDomain(name: 'ui', events: [event]);
      final allDomains = {'ui': domain};

      final result = renderer.renderDomainFile('ui', domain, allDomains);

      expect(result, contains('const allowedOptionValues = <int>{1, 2, 3};'));
      expect(result, contains('if (!allowedOptionValues.contains(option))'));
      expect(result, contains('throw ArgumentError.value('));
      expect(result, contains('must be one of 1, 2, 3'));
    });

    test('renders event with validation rules', () {
      final event = AnalyticsEvent(
        name: 'search',
        description: 'Search items',
        parameters: [
          AnalyticsParameter(
            name: 'query',
            type: 'string',
            isNullable: false,
            regex: '^[a-z]+\$',
            minLength: 3,
            maxLength: 20,
          ),
          AnalyticsParameter(
            name: 'count',
            type: 'int',
            isNullable: false,
            min: 1,
            max: 100,
          ),
        ],
      );
      final domain = AnalyticsDomain(name: 'items', events: [event]);
      final allDomains = {'items': domain};

      final result = renderer.renderDomainFile('items', domain, allDomains);

      // Regex
      expect(result, contains("if (!RegExp(r'^[a-z]+\$').hasMatch(query)) {"));
      expect(result, contains('throw ArgumentError.value('));
      expect(result, contains(r"'must match regex ^[a-z]+\$',"));

      // Length
      expect(result, contains('if (query.length < 3 || query.length > 20) {'));
      expect(result, contains("'length must be between 3 and 20',"));

      // Range
      expect(result, contains('if (count < 1 || count > 100) {'));
      expect(result, contains("'must be between 1 and 100',"));
    });

    test(
        'adds @Deprecated when interpolation used (even if strict_event_names is true, assuming parser bypassed)',
        () {
      config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'lib/analytics',
        strictEventNames: true,
        naming: NamingStrategy(convention: EventNamingConvention.original),
      );
      renderer = EventRenderer(config);

      final event = AnalyticsEvent(
        name: 'view_{page}',
        description: 'View page',
        parameters: [
          AnalyticsParameter(name: 'page', type: 'string', isNullable: false),
        ],
      );
      final domain = AnalyticsDomain(name: 'screen', events: [event]);
      final allDomains = {'screen': domain};

      final result = renderer.renderDomainFile('screen', domain, allDomains);
      expect(result, contains('@Deprecated'));
      expect(result, contains('string interpolation'));
    });

    test('renders dual-write event with method call when parameters match', () {
      final sourceEvent = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: [
          AnalyticsParameter(
            name: 'method',
            type: 'string',
            isNullable: false,
          ),
        ],
        dualWriteTo: ['auth.login_legacy'],
      );
      final targetEvent = AnalyticsEvent(
        name: 'login_legacy',
        description: 'Legacy login event',
        parameters: [
          AnalyticsParameter(
            name: 'method',
            type: 'string',
            isNullable: false,
          ),
        ],
      );
      final domain =
          AnalyticsDomain(name: 'auth', events: [sourceEvent, targetEvent]);
      final allDomains = {'auth': domain};

      final result = renderer.renderDomainFile('auth', domain, allDomains);

      expect(result, contains('logAuthLogin('));
      expect(
          result,
          contains(
              'logAuthLoginLegacy(method: method, parameters: parameters);'));
    });

    test(
        'renders dual-write event with logEvent when required parameter missing',
        () {
      final sourceEvent = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: [
          AnalyticsParameter(
            name: 'method',
            type: 'string',
            isNullable: false,
          ),
        ],
        dualWriteTo: ['auth.login_legacy'],
      );
      final targetEvent = AnalyticsEvent(
        name: 'login_legacy',
        description: 'Legacy login event',
        parameters: [
          AnalyticsParameter(
            name: 'method',
            type: 'string',
            isNullable: false,
          ),
          AnalyticsParameter(
            name: 'device',
            type: 'string',
            isNullable: false, // Required parameter not in source
          ),
        ],
      );
      final domain =
          AnalyticsDomain(name: 'auth', events: [sourceEvent, targetEvent]);
      final allDomains = {'auth': domain};

      final result = renderer.renderDomainFile('auth', domain, allDomains);

      expect(result, contains('logAuthLogin('));
      expect(result, contains('// Dual-write to: auth.login_legacy'));
      expect(result, contains('logger.logEvent('));
      expect(result, contains('name: "auth_login_legacy",'));
      expect(result, isNot(contains('logAuthLoginLegacy(method:')));
    });

    test(
        'renders dual-write event with method call when both parameters are enums',
        () {
      final sourceEvent = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: [
          AnalyticsParameter(
            name: 'method',
            type: 'string',
            isNullable: false,
            allowedValues: ['email', 'google'],
          ),
        ],
        dualWriteTo: ['auth.login_legacy'],
      );
      final targetEvent = AnalyticsEvent(
        name: 'login_legacy',
        description: 'Legacy login event',
        parameters: [
          AnalyticsParameter(
            name: 'method',
            type: 'string',
            isNullable: false,
            allowedValues: ['email', 'google'],
          ),
        ],
      );
      final domain =
          AnalyticsDomain(name: 'auth', events: [sourceEvent, targetEvent]);
      final allDomains = {'auth': domain};

      final result = renderer.renderDomainFile('auth', domain, allDomains);

      expect(result, contains('logAuthLogin('));
      expect(
          result,
          contains(
              'logAuthLoginLegacy(method: method, parameters: parameters);'));
    });

    test(
        'renders dual-write event with method call when source is enum and target is string',
        () {
      final sourceEvent = AnalyticsEvent(
        name: 'login',
        description: 'User logs in',
        parameters: [
          AnalyticsParameter(
            name: 'method',
            type: 'string',
            isNullable: false,
            allowedValues: ['email', 'google'],
          ),
        ],
        dualWriteTo: ['auth.login_legacy'],
      );
      final targetEvent = AnalyticsEvent(
        name: 'login_legacy',
        description: 'Legacy login event',
        parameters: [
          AnalyticsParameter(
            name: 'method',
            type: 'string',
            isNullable: false,
            // No allowedValues, so it's a plain string
          ),
        ],
      );
      final domain =
          AnalyticsDomain(name: 'auth', events: [sourceEvent, targetEvent]);
      final allDomains = {'auth': domain};

      final result = renderer.renderDomainFile('auth', domain, allDomains);

      expect(result, contains('logAuthLogin('));
      expect(
          result,
          contains(
              'logAuthLoginLegacy(method: method.value, parameters: parameters);'));
    });
  });

  group('ContextRenderer', () {
    late ContextRenderer renderer;

    setUp(() {
      renderer = ContextRenderer();
    });

    test('renders context file with capability and mixin', () {
      final properties = [
        AnalyticsParameter(
          name: 'user_id',
          type: 'string',
          isNullable: false,
          description: 'User ID',
        ),
      ];

      final result = renderer.renderContextFile('user_context', properties);

      expect(
          result,
          contains(
              'abstract class UserContextCapability implements AnalyticsCapability'));
      expect(result, contains('mixin AnalyticsUserContext on AnalyticsBase'));
      expect(result, contains('void setUserContextUserId(String value)'));
      expect(
          result,
          contains(
              "capability(userContextKey)?.setUserContextProperty('user_id', value);"));
    });

    test('renders user properties context', () {
      final properties = [
        AnalyticsParameter(
          name: 'role',
          type: 'string',
          isNullable: true,
        ),
      ];

      final result = renderer.renderContextFile('user_properties', properties);

      expect(result, contains('abstract class UserPropertiesCapability'));
      expect(
          result,
          contains(
              'void setUserPropertiesProperty(String name, Object? value);'));
      expect(result, contains('void setUserPropertiesRole(String? value)'));
    });
  });

  group('AnalyticsClassRenderer', () {
    late AnalyticsConfig config;
    late AnalyticsClassRenderer renderer;

    setUp(() {
      config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'lib/analytics',
      );
      renderer = AnalyticsClassRenderer(config);
    });

    test('renders Analytics class with mixins and singleton', () {
      final domains = {
        'auth': AnalyticsDomain(name: 'auth', events: []),
        'shop': AnalyticsDomain(name: 'shop', events: []),
      };
      final contexts = {
        'user_context': <AnalyticsParameter>[],
      };

      final result = renderer.renderAnalyticsClass(domains, contexts: contexts);

      expect(result, contains('final class Analytics extends AnalyticsBase'));
      expect(result,
          contains('with AnalyticsAuth, AnalyticsShop, AnalyticsUserContext'));
      expect(result, contains('static Analytics get instance'));
      expect(result, contains('static void initialize(IAnalytics analytics)'));
      expect(
          result,
          contains(
              'Analytics.initialize() must be called before accessing Analytics.instance'));
    });

    test('renders analytics plan', () {
      config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'lib/analytics',
        generatePlan: true,
      );
      renderer = AnalyticsClassRenderer(config);

      final domains = {
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

      final result = renderer.renderAnalyticsClass(domains);

      expect(
          result,
          contains(
              'static const List<AnalyticsDomain> plan = <AnalyticsDomain>['));
      expect(result, contains("name: 'auth',"));
      expect(result, contains("name: 'login',"));
    });

    test('renders analytics plan with event identifier', () {
      config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'lib/analytics',
        generatePlan: true,
      );
      renderer = AnalyticsClassRenderer(config);

      final domains = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              identifier: 'user_login_v2',
              parameters: [],
            ),
          ],
        ),
      };

      final result = renderer.renderAnalyticsClass(domains);

      expect(result, contains("identifier: 'user_login_v2',"));
    });

    test('renders analytics plan with event metadata', () {
      config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'lib/analytics',
        generatePlan: true,
      );
      renderer = AnalyticsClassRenderer(config);

      final domains = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              meta: {
                'owner': 'auth-team',
                'is_secure': false,
                'version': 2,
              },
              parameters: [],
            ),
          ],
        ),
      };

      final result = renderer.renderAnalyticsClass(domains);

      expect(result, contains('meta: <String, Object?>{'));
      expect(result, contains("'owner': 'auth-team',"));
      expect(result, contains("'is_secure': false,"));
      expect(result, contains("'version': 2,"));
    });

    test('renders analytics plan with parameter codeName', () {
      config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'lib/analytics',
        generatePlan: true,
      );
      renderer = AnalyticsClassRenderer(config);

      final domains = {
        'auth': AnalyticsDomain(
          name: 'auth',
          events: [
            AnalyticsEvent(
              name: 'login',
              description: 'Login',
              parameters: [
                AnalyticsParameter(
                  name: 'login_method',
                  codeName: 'method',
                  type: 'string',
                  isNullable: false,
                ),
              ],
            ),
          ],
        ),
      };

      final result = renderer.renderAnalyticsClass(domains);

      expect(result, contains("name: 'login_method',"));
      expect(result, contains("codeName: 'method',"));
    });

    test('renders analytics plan with parameter metadata and allowed values',
        () {
      config = AnalyticsConfig(
        eventsPath: 'events',
        outputPath: 'lib/analytics',
        generatePlan: true,
      );
      renderer = AnalyticsClassRenderer(config);

      final domains = {
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
                  allowedValues: ['email', 'google', "it's special"],
                  meta: {
                    'is_sensitive': true,
                    'required': true,
                    "special_key'": "value'with'quotes",
                  },
                ),
              ],
            ),
          ],
        ),
      };

      final result = renderer.renderAnalyticsClass(domains);

      expect(result, contains('allowedValues: <Object>['));
      expect(result, contains("'email',"));
      expect(result, contains("'google',"));
      expect(result, contains("'it\\'s special',"));
      expect(result, contains('meta: <String, Object?>{'));
      expect(result, contains("'is_sensitive': true,"));
      expect(result, contains("'required': true,"));
      expect(result, contains("'special_key\\'': 'value\\'with\\'quotes',"));
    });
  });
}
