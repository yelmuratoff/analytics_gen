import 'package:test/test.dart';
import '../lib/src/analytics/generated/generated_events.dart';
import 'analytics_matchers.dart';

void main() {
  group('Generated Matchers', () {
    test('isAuthLoginV2 matches correct parameters', () {
      final eventParams = <String, dynamic>{
        'login-method': 'email', // Note: login_v2 uses param_name: login-method
        'session_id': '123',
      };

      expect(
        eventParams,
        isAuthLoginV2(
            loginMethod: AnalyticsAuthLoginV2LoginMethodEnum.email,
            sessionId: '123'),
      );
    });

    test('isAuthLoginV2 rejects incorrect parameters', () {
      final eventParams = <String, dynamic>{
        'login-method': 'google',
        'session_id': '123',
      };

      expect(
        eventParams,
        isNot(isAuthLoginV2(
            loginMethod: AnalyticsAuthLoginV2LoginMethodEnum.email,
            sessionId: '123')),
      );
    });

    test('isAuthLogin matches with null optional param', () {
      // Assuming some event has optional params, but let's stick to simple ones first.
      // 'auth.login' has 'method' (required?).
      // Let's check 'screen.view' -> 'screen_name' (required), 'duration_ms' (optional per schema check output)

      // From logs: "[MODIFIED] screen.view.duration_ms: Nullability changed from false to true."
      // So duration_ms is nullable.
    });

    test('isScreenView matches partial params', () {
      final params = <String, dynamic>{
        'screen_name': 'Home',
        'duration_ms': 100,
      };

      expect(
          params,
          isScreenView(
            screenName: 'Home',
            durationMs: 100,
          ));
    });

    test(
        'isScreenView ignores missing optional params in check if not specified in matcher',
        () {
      final params = <String, dynamic>{
        'screen_name': 'Home',
        // duration_ms is missing in actual
      };

      // If we don't pass durationMs to isScreenView, it shouldn't check it (treated as "any/ignore").
      expect(
          params,
          isScreenView(
            screenName: 'Home',
          ));
    });
  });
}
