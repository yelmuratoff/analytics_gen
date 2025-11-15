import 'package:analytics_gen/analytics_gen.dart';
import 'package:test/test.dart';

void main() {
  group('MockAnalyticsService', () {
    late MockAnalyticsService service;

    setUp(() {
      service = MockAnalyticsService();
    });

    test('starts with empty events list', () {
      expect(service.events, isEmpty);
      expect(service.totalEvents, equals(0));
    });

    test('logs events correctly', () {
      // Arrange & Act
      service.logEvent(name: 'test_event', parameters: {'key': 'value'});

      // Assert
      expect(service.totalEvents, equals(1));
      expect(service.events.first['name'], equals('test_event'));
      expect(service.events.first['parameters'], equals({'key': 'value'}));
    });

    test('logs multiple events', () {
      // Arrange & Act
      service.logEvent(name: 'event1');
      service.logEvent(name: 'event2');
      service.logEvent(name: 'event3');

      // Assert
      expect(service.totalEvents, equals(3));
    });

    test('getEventsByName returns matching events', () {
      // Arrange
      service.logEvent(name: 'login');
      service.logEvent(name: 'logout');
      service.logEvent(name: 'login');

      // Act
      final loginEvents = service.getEventsByName('login');

      // Assert
      expect(loginEvents.length, equals(2));
      expect(loginEvents.every((e) => e['name'] == 'login'), isTrue);
    });

    test('getEventCount returns correct count', () {
      // Arrange
      service.logEvent(name: 'click');
      service.logEvent(name: 'click');
      service.logEvent(name: 'scroll');

      // Act & Assert
      expect(service.getEventCount('click'), equals(2));
      expect(service.getEventCount('scroll'), equals(1));
      expect(service.getEventCount('unknown'), equals(0));
    });

    test('clear removes all events', () {
      // Arrange
      service.logEvent(name: 'event1');
      service.logEvent(name: 'event2');
      expect(service.totalEvents, equals(2));

      // Act
      service.clear();

      // Assert
      expect(service.events, isEmpty);
      expect(service.totalEvents, equals(0));
    });

    test('stores timestamp with each event', () {
      // Arrange & Act
      service.logEvent(name: 'test');

      // Assert
      final event = service.events.first;
      expect(event.containsKey('timestamp'), isTrue);
      expect(event['timestamp'], isNotEmpty);
      final record = service.records.first;
      expect(record.timestamp, isA<DateTime>());
    });

    test('handles null parameters', () {
      // Arrange & Act
      service.logEvent(name: 'test');

      // Assert
      final event = service.events.first;
      expect(event['parameters'], equals({}));
    });

    test('handles empty parameters', () {
      // Arrange & Act
      service.logEvent(name: 'test', parameters: {});

      // Assert
      final event = service.events.first;
      expect(event['parameters'], equals({}));
    });

    test('records expose typed snapshots', () {
      service.logEvent(name: 'typed', parameters: {'key': 'value'});

      expect(service.records, hasLength(1));
      final record = service.records.first;
      expect(record, isA<RecordedAnalyticsEvent>());
      expect(record.name, equals('typed'));
      expect(record.parameters, containsPair('key', 'value'));
    });

    test('records and parameters are immutable', () {
      service.logEvent(name: 'immutable');

      final records = service.records;
      expect(() => records.add(records.first), throwsUnsupportedError);
      expect(
        () => service.records.first.parameters['foo'] = 'bar',
        throwsUnsupportedError,
      );
    });
  });
}
