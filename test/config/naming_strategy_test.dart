import 'package:analytics_gen/src/config/naming_strategy.dart';
import 'package:test/test.dart';

void main() {
  group('NamingStrategy', () {
    test('defaults to snake_case convention', () {
      final strategy = NamingStrategy();
      expect(strategy.convention, EventNamingConvention.snakeCase);
    });

    test('defaults to legacy template but applies snake_case transformation',
        () {
      // Default: {domain}: {event}
      // snake_case on "domain: event" -> "domain_event"
      final strategy = NamingStrategy();
      final result =
          strategy.renderEventName(domain: 'my_domain', event: 'my_event');
      expect(result, 'my_domain_my_event');
    });

    test('supports Title Case convention', () {
      final strategy =
          NamingStrategy(convention: EventNamingConvention.titleCase);
      // "my_domain: my_event" -> "My Domain: My Event"
      final result =
          strategy.renderEventName(domain: 'my_domain', event: 'my_event');
      expect(result, 'My Domain: My Event');
    });

    test('supports original convention', () {
      final strategy =
          NamingStrategy(convention: EventNamingConvention.original);
      final result =
          strategy.renderEventName(domain: 'my_domain', event: 'my_event');
      expect(result, 'my_domain: my_event');
    });

    group('fromYaml', () {
      test('parses snake_case', () {
        final strategy = NamingStrategy.fromYaml({'casing': 'snake_case'});
        expect(strategy.convention, EventNamingConvention.snakeCase);
      });

      test('parses title_case', () {
        final strategy = NamingStrategy.fromYaml({'casing': 'title_case'});
        expect(strategy.convention, EventNamingConvention.titleCase);
      });

      test('parses original', () {
        final strategy = NamingStrategy.fromYaml({'casing': 'original'});
        expect(strategy.convention, EventNamingConvention.original);
      });

      test('defaults to snake_case if missing', () {
        final strategy = NamingStrategy.fromYaml({});
        expect(strategy.convention, EventNamingConvention.snakeCase);
      });
    });

    group('Casing Logic', () {
      test('snake_case logic handles colons and spaces', () {
        // NamingStrategy internal logic isn't exposed directly, test via renderEventName
        final strategy = NamingStrategy(
          convention: EventNamingConvention.snakeCase,
          eventNameTemplate: '{domain} {event}',
        );
        expect(
          strategy.renderEventName(domain: 'User Check', event: 'Log In'),
          'user_check_log_in',
        );
      });

      test('title_case logic handles underscores', () {
        final strategy = NamingStrategy(
          convention: EventNamingConvention.titleCase,
          eventNameTemplate: '{event}', // Ignore domain
        );
        expect(
          strategy.renderEventName(
              domain: 'x', event: 'order_completed_successfully'),
          'Order Completed Successfully',
        );
      });

      test('title_case preserves colon separator from explicit template', () {
        final strategy = NamingStrategy(
          convention: EventNamingConvention.titleCase,
          eventNameTemplate: '{domain}: {event}',
        );
        expect(
          strategy.renderEventName(
              domain: 'chat', event: 'under_dev_sheet_shown'),
          'Chat: Under Dev Sheet Shown',
        );
      });
    });
  });
}
