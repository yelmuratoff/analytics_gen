import 'package:analytics_gen/analytics_gen.dart';
import 'package:test/test.dart';

void main() {
  group('MultiProviderAnalytics', () {
    late MockAnalyticsService service1;
    late MockAnalyticsService service2;
    late MultiProviderAnalytics multiProvider;
    late List<Object> errors;

    setUp(() {
      service1 = MockAnalyticsService();
      service2 = MockAnalyticsService();
      errors = [];
      multiProvider = MultiProviderAnalytics(
        [service1, service2],
        onError: (error, _) => errors.add(error),
      );
    });

    test('forwards events to all providers', () {
      // Arrange & Act
      multiProvider.logEvent(
        name: 'test_event',
        parameters: {'key': 'value'},
      );

      // Assert
      expect(service1.totalEvents, equals(1));
      expect(service2.totalEvents, equals(1));
      expect(service1.events.first['name'], equals('test_event'));
      expect(service2.events.first['name'], equals('test_event'));
    });

    test('returns correct provider count', () {
      expect(multiProvider.providerCount, equals(2));
    });

    test('can add new provider', () {
      // Arrange
      final service3 = MockAnalyticsService();

      // Act
      multiProvider.addProvider(service3);

      // Assert
      expect(multiProvider.providerCount, equals(3));

      multiProvider.logEvent(name: 'test');
      expect(service3.totalEvents, equals(1));
    });

    test('can remove provider', () {
      // Act
      multiProvider.removeProvider(service1);

      // Assert
      expect(multiProvider.providerCount, equals(1));

      multiProvider.logEvent(name: 'test');
      expect(service1.totalEvents, equals(0));
      expect(service2.totalEvents, equals(1));
    });

    test('continues with other providers if one fails', () {
      // Arrange
      final failingProvider = _FailingAnalyticsService();
      final multiWithFailure = MultiProviderAnalytics([
        failingProvider,
        service1,
      ], onError: (error, _) => errors.add(error));

      // Act & Assert - should not throw
      expect(
        () => multiWithFailure.logEvent(name: 'test'),
        returnsNormally,
      );

      // Service1 should still receive the event
      expect(service1.totalEvents, equals(1));
      expect(errors, isNotEmpty);
    });

    test('works with empty provider list', () {
      // Arrange
      final emptyMulti = MultiProviderAnalytics([]);

      // Act & Assert - should not throw
      expect(
        () => emptyMulti.logEvent(name: 'test'),
        returnsNormally,
      );
    });
  });
}

/// Mock analytics service that always throws
class _FailingAnalyticsService implements IAnalytics {
  @override
  void logEvent({
    required String name,
    AnalyticsParams? parameters,
  }) {
    throw Exception('Intentional failure');
  }
}
