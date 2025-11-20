import 'dart:io';

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

    test('addProvider returns new instance with added provider', () {
      // Arrange
      final service3 = MockAnalyticsService();

      // Act - functional update
      final updated = multiProvider.addProvider(service3);

      // Assert - original unchanged
      expect(multiProvider.providerCount, equals(2));
      expect(updated.providerCount, equals(3));

      updated.logEvent(name: 'test');
      expect(service3.totalEvents, equals(1));
      expect(
          service1.totalEvents, equals(1)); // Both original providers get event
      expect(service2.totalEvents, equals(1));
    });

    test('withoutProvider returns new instance without specified provider', () {
      // Act - functional update
      final updated = multiProvider.removeProvider(service1);

      // Assert - original unchanged
      expect(multiProvider.providerCount, equals(2));
      expect(updated.providerCount, equals(1));

      updated.logEvent(name: 'test');
      expect(service1.totalEvents, equals(0)); // Not in updated instance
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

    test('continues with other providers when SocketException is thrown', () {
      final socketFailing = _FailingSocketAnalyticsService();
      final multiWithSocketFailure = MultiProviderAnalytics([
        socketFailing,
        service1,
      ], onError: (error, _) => errors.add(error));

      expect(
          () => multiWithSocketFailure.logEvent(name: 'test'), returnsNormally);
      expect(service1.totalEvents, equals(1));
      expect(errors, isNotEmpty);
      expect(errors.first, isA<SocketException>());
    });

    test('continues with other providers when FormatException is thrown', () {
      final formatFailing = _FailingFormatAnalyticsService();
      final multiWithFormatFailure = MultiProviderAnalytics([
        formatFailing,
        service1,
      ], onError: (error, _) => errors.add(error));

      expect(
          () => multiWithFormatFailure.logEvent(name: 'test'), returnsNormally);
      expect(service1.totalEvents, equals(1));
      expect(errors, isNotEmpty);
      expect(errors.first, isA<FormatException>());
    });

    test('reports failure details for logging/metrics hooks', () {
      // Arrange
      final failingProvider = _FailingAnalyticsService();
      final failures = <MultiProviderAnalyticsFailure>[];
      final multiWithFailure = MultiProviderAnalytics(
        [failingProvider, service1],
        onError: (error, _) => errors.add(error),
        onProviderFailure: (failure) => failures.add(failure),
      );

      // Act
      multiWithFailure.logEvent(
        name: 'important_event',
        parameters: {'source': 'test'},
      );

      // Assert
      expect(failures, hasLength(1));
      final failure = failures.single;
      expect(failure.provider, equals(failingProvider));
      expect(
          failure.providerName, equals(failingProvider.runtimeType.toString()));
      expect(failure.eventName, equals('important_event'));
      expect(failure.parameters, isNotNull);
      expect(failure.parameters!['source'], equals('test'));
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

    test('respects provider filters', () {
      // Arrange
      final service3 = MockAnalyticsService();

      // Only service1 and service3 receive events where name contains 'allowed'
      final filteredMulti = MultiProviderAnalytics([
        service1,
        service2,
        service3,
      ], providerFilters: {
        service1: (name, _) => name.contains('allowed'),
        service2: (name, _) => false,
        service3: (name, _) => true,
      });

      // Act
      filteredMulti.logEvent(name: 'allowed_event');
      filteredMulti.logEvent(name: 'denied_event');

      // Assert
      expect(service1.totalEvents, equals(1)); // only allowed_event
      expect(service2.totalEvents, equals(0)); // never allowed
      expect(service3.totalEvents, equals(2)); // both calls allowed
    });

    test('addProvider preserves providerFilter passed in', () {
      final service3 = MockAnalyticsService();

      final updated = multiProvider.addProvider(
        service3,
        providerFilter: (name, _) => name == 'allowed',
      );

      // Original unchanged
      expect(multiProvider.providerCount, equals(2));
      expect(updated.providerCount, equals(3));

      updated.logEvent(name: 'allowed');
      expect(service3.totalEvents, equals(1));

      updated.logEvent(name: 'denied');
      expect(service3.totalEvents, equals(1));
    });

    group('logEventAsync', () {
      test('forwards events to all providers asynchronously', () async {
        final asyncProvider = _AsyncLoggingProvider(service2);
        final multiAsync = MultiProviderAnalytics([
          service1,
          asyncProvider,
        ]);

        await multiAsync.logEventAsync(name: 'async_test');

        expect(service1.totalEvents, equals(1));
        expect(service2.totalEvents, equals(1));
      });

      test('respects provider filters in async path', () async {
        final asyncProvider = _AsyncLoggingProvider(service2);

        final multiAsync = MultiProviderAnalytics([
          service1,
          asyncProvider,
        ], providerFilters: {
          service1: (name, _) => name == 'allowed',
          asyncProvider: (name, _) => false,
        });

        await multiAsync.logEventAsync(name: 'allowed');

        // service1 should receive the event; asyncProvider should be filtered out
        expect(service1.totalEvents, equals(1));
        expect(service2.totalEvents, equals(0));

        await multiAsync.logEventAsync(name: 'denied');
        // no additional events delivered
        expect(service1.totalEvents, equals(1));
        expect(service2.totalEvents, equals(0));
      });

      test(
          'reports failure details when async provider fails via onProviderFailure',
          () async {
        final failing = _FailingAsyncAnalyticsService();
        final failures = <MultiProviderAnalyticsFailure>[];
        final errors = <Object>[];

        final multiWithFailure = MultiProviderAnalytics(
          [failing, service1],
          onError: (error, _) => errors.add(error),
          onProviderFailure: (failure) => failures.add(failure),
        );

        await multiWithFailure.logEventAsync(name: 'async_fail');

        expect(service1.totalEvents, equals(1));
        expect(failures, isNotEmpty);
        expect(failures.single.provider, equals(failing));
        expect(failures.single.stackTrace, isA<StackTrace>());
        expect(errors, isNotEmpty);
      });

      test('reports failure details when non-async provider fails in microtask',
          () async {
        final failing = _FailingAnalyticsService();
        final failures = <MultiProviderAnalyticsFailure>[];
        final errors = <Object>[];

        final multiWithFailure = MultiProviderAnalytics(
          [failing, service1],
          onError: (error, _) => errors.add(error),
          onProviderFailure: (failure) => failures.add(failure),
        );

        await multiWithFailure.logEventAsync(name: 'microtask_fail');

        expect(service1.totalEvents, equals(1));
        expect(failures, isNotEmpty);
        expect(failures.single.provider, equals(failing));
        expect(failures.single.stackTrace, isA<StackTrace>());
        expect(errors, isNotEmpty);
      });
    });

    test('continues with other providers when async provider fails', () async {
      final failing = _FailingAsyncAnalyticsService();
      final errors = <Object>[];
      final multiWithFailure = MultiProviderAnalytics(
        [failing, service1],
        onError: (error, _) => errors.add(error),
      );

      // Should not throw when awaiting
      await multiWithFailure.logEventAsync(name: 'async_fail');

      // Synchronous provider still receives event
      expect(service1.totalEvents, equals(1));
      expect(errors, isNotEmpty);
    });

    group('Capability Resolution', () {
      test('returns capability from first provider that supports it', () {
        final provider1 = _ProviderWithCapability('provider1');
        final provider2 = _ProviderWithCapability('provider2');
        final multi = MultiProviderAnalytics([provider1, provider2]);

        final capability =
            multi.capabilityResolver.getCapability(_testCapabilityKey);

        expect(capability, isNotNull);
        expect(capability!.source, equals('provider1'));
      });

      test('skips providers that do not support the capability', () {
        final provider1 = MockAnalyticsService(); // No capabilities
        final provider2 = _ProviderWithCapability('provider2');
        final multi = MultiProviderAnalytics([provider1, provider2]);

        final capability =
            multi.capabilityResolver.getCapability(_testCapabilityKey);

        expect(capability, isNotNull);
        expect(capability!.source, equals('provider2'));
      });

      test('returns null if no provider supports the capability', () {
        final provider1 = MockAnalyticsService();
        final provider2 = MockAnalyticsService();
        final multi = MultiProviderAnalytics([provider1, provider2]);

        final capability =
            multi.capabilityResolver.getCapability(_testCapabilityKey);

        expect(capability, isNull);
      });
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

/// An async-capable provider that executes logging after a short delay.
class _AsyncLoggingProvider implements IAnalytics, IAsyncAnalytics {

  _AsyncLoggingProvider(this._delegate);
  final MockAnalyticsService _delegate;

  @override
  void logEvent({required String name, AnalyticsParams? parameters}) {
    _delegate.logEvent(name: name, parameters: parameters);
  }

  @override
  Future<void> logEventAsync(
      {required String name, AnalyticsParams? parameters}) async {
    await Future.delayed(const Duration(milliseconds: 5));
    _delegate.logEvent(name: name, parameters: parameters);
  }

  int get totalEvents => _delegate.totalEvents;
}

class _FailingAsyncAnalyticsService implements IAnalytics, IAsyncAnalytics {
  @override
  void logEvent({required String name, AnalyticsParams? parameters}) {
    // Synchronous path should succeed if used, but async path fails.
    // We do nothing here to keep behaviour predictable in tests.
  }

  @override
  Future<void> logEventAsync(
      {required String name, AnalyticsParams? parameters}) {
    return Future.error(Exception('Intentional async failure'));
  }
}

/// Provider that throws a [SocketException] to simulate network errors.
class _FailingSocketAnalyticsService implements IAnalytics {
  @override
  void logEvent({required String name, AnalyticsParams? parameters}) {
    throw SocketException('Network failure');
  }
}

/// Provider that throws a [FormatException] to simulate validation errors.
class _FailingFormatAnalyticsService implements IAnalytics {
  @override
  void logEvent({required String name, AnalyticsParams? parameters}) {
    throw FormatException('Invalid event');
  }
}

abstract class _TestCapability implements AnalyticsCapability {
  String get source;
}

const _testCapabilityKey = CapabilityKey<_TestCapability>('test_capability');

class _TestCapabilityImpl implements _TestCapability {
  _TestCapabilityImpl(this.source);
  @override
  final String source;
}

class _ProviderWithCapability
    with CapabilityProviderMixin
    implements IAnalytics {

  _ProviderWithCapability(this.name) {
    registerCapability(_testCapabilityKey, _TestCapabilityImpl(name));
  }
  final String name;

  @override
  void logEvent({required String name, AnalyticsParams? parameters}) {}
}
