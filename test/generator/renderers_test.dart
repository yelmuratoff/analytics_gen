import 'package:analytics_gen/src/config/analytics_config.dart';
import 'package:analytics_gen/src/generator/renderers/analytics_class_renderer.dart';
import 'package:analytics_gen/src/generator/renderers/context_renderer.dart';
import 'package:analytics_gen/src/generator/renderers/event_renderer.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
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

      final result = renderer.renderDomainFile('auth', domain);

      expect(result, contains('mixin AnalyticsAuth on AnalyticsBase'));
      expect(result, contains('void logAuthLogin({'));
      expect(result, contains('required String method,'));
      expect(result, contains('logger.logEvent('));
      expect(result, contains('name: "auth: login",'));
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

      final result = renderer.renderDomainFile('legacy', domain);

      expect(
          result, contains('@Deprecated(\'Use logLegacyNewEvent instead.\')'));
      expect(result, contains('void logLegacyOldEvent()'));
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

      final result = renderer.renderDomainFile('items', domain);

      expect(result, contains('enum AnalyticsItemsFilterSortEnum {'));
      expect(result, contains("asc('asc'),"));
      expect(result, contains("desc('desc');"));
      expect(result, contains('required AnalyticsItemsFilterSortEnum sort,'));
      expect(result, contains('"sort": sort.value,'));
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

      final result = renderer.renderDomainFile('items', domain);

      // Regex
      expect(result, contains("if (!RegExp(r'^[a-z]+\$').hasMatch(query)) {"));
      expect(result, contains('throw ArgumentError.value('));
      expect(result, contains("'must match regex ^[a-z]+\$',"));

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

      final result = renderer.renderDomainFile('screen', domain);
      expect(result, contains('@Deprecated'));
      expect(result, contains('string interpolation'));
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
      expect(result, contains('Analytics.initialize() must be called before accessing Analytics.instance'));
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
  });
}
