import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/tracking_plan.dart';
import 'package:analytics_gen/src/services/creation_date_injector.dart';
import 'package:test/test.dart';

void main() {
  group('CreationDateInjector', () {
    const injector = CreationDateInjector();

    TrackingPlan makePlan(Map<String, List<AnalyticsEvent>> domainEvents) {
      return TrackingPlan(
        domains: domainEvents.map(
          (name, events) => MapEntry(
            name,
            AnalyticsDomain(name: name, events: events),
          ),
        ),
        contexts: const {},
      );
    }

    AnalyticsEvent makeEvent(String name, {Map<String, dynamic> meta = const {}}) {
      return AnalyticsEvent(
        name: name,
        description: 'Test event',
        parameters: const [],
        meta: meta,
      );
    }

    test('injects tracking_creation_date into event meta', () {
      final plan = makePlan({
        'auth': [makeEvent('login')],
      });

      final ledger = {'auth.login': '2026-01-15'};
      final result = injector.inject(plan, ledger);

      final event = result.domains['auth']!.events.first;
      expect(event.meta['tracking_creation_date'], '2026-01-15');
    });

    test('preserves existing meta keys alongside injected date', () {
      final plan = makePlan({
        'auth': [makeEvent('login', meta: {'owner': 'auth-team', 'tier': 'critical'})],
      });

      final ledger = {'auth.login': '2026-01-15'};
      final result = injector.inject(plan, ledger);

      final meta = result.domains['auth']!.events.first.meta;
      expect(meta['tracking_creation_date'], '2026-01-15');
      expect(meta['owner'], 'auth-team');
      expect(meta['tier'], 'critical');
    });

    test('ledger value takes precedence over manually set tracking_creation_date', () {
      final plan = makePlan({
        'auth': [makeEvent('login', meta: {'tracking_creation_date': '2099-12-31'})],
      });

      final ledger = {'auth.login': '2026-01-15'};
      final result = injector.inject(plan, ledger);

      final meta = result.domains['auth']!.events.first.meta;
      expect(meta['tracking_creation_date'], '2026-01-15');
    });

    test('does not inject when event has no ledger entry', () {
      final plan = makePlan({
        'auth': [makeEvent('login')],
      });

      final result = injector.inject(plan, const {});

      final event = result.domains['auth']!.events.first;
      expect(event.meta.containsKey('tracking_creation_date'), isFalse);
    });

    test('returns unmodified plan when ledger is empty', () {
      final plan = makePlan({
        'auth': [makeEvent('login'), makeEvent('logout')],
      });

      final result = injector.inject(plan, const {});

      expect(result.domains['auth']!.events[0].meta, isEmpty);
      expect(result.domains['auth']!.events[1].meta, isEmpty);
    });

    test('handles multiple domains and events', () {
      final plan = makePlan({
        'auth': [makeEvent('login'), makeEvent('logout')],
        'purchase': [makeEvent('complete')],
      });

      final ledger = {
        'auth.login': '2026-01-15',
        'auth.logout': '2026-02-20',
        'purchase.complete': '2026-03-10',
      };

      final result = injector.inject(plan, ledger);

      expect(
        result.domains['auth']!.events[0].meta['tracking_creation_date'],
        '2026-01-15',
      );
      expect(
        result.domains['auth']!.events[1].meta['tracking_creation_date'],
        '2026-02-20',
      );
      expect(
        result.domains['purchase']!.events[0].meta['tracking_creation_date'],
        '2026-03-10',
      );
    });

    test('preserves contexts unchanged', () {
      final plan = TrackingPlan(
        domains: {
          'auth': AnalyticsDomain(
            name: 'auth',
            events: [makeEvent('login')],
          ),
        },
        contexts: const {'theme': []},
      );

      final result = injector.inject(plan, {'auth.login': '2026-01-15'});

      expect(result.contexts, plan.contexts);
    });
  });
}
