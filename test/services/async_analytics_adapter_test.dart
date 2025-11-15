import 'package:analytics_gen/analytics_gen.dart';
import 'package:test/test.dart';

void main() {
  group('AsyncAnalyticsAdapter', () {
    test('awaits wrapped synchronous provider', () async {
      final mock = MockAnalyticsService();
      final asyncAdapter = AsyncAnalyticsAdapter(mock);

      await asyncAdapter.logEventAsync(name: 'async_event', parameters: {'k': 'v'});

      expect(mock.totalEvents, equals(1));
      expect(mock.records.first.name, equals('async_event'));
    });
  });
}
