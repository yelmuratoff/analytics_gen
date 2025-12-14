// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import
// ignore_for_file: directives_ordering, unnecessary_string_interpolations
// coverage:ignore-file

import 'package:flutter_test/flutter_test.dart';
import 'package:analytics_gen/analytics_gen.dart';
import '../lib/src/analytics/generated/analytics.dart';
import '../lib/src/analytics/generated/generated_events.dart';

void main() {
  group('Analytics Plan Tests', () {
    late Analytics analytics;

    setUp(() {
      analytics = Analytics(MockAnalyticsService());
    });

    group('auth', () {
      test('logAuthLogin constructs correctly', () {
        expect(() => analytics.logAuthLogin(
          method: 'test',
        ), returnsNormally);
      });
      test('logAuthLoginV2 constructs correctly', () {
        expect(() => analytics.logAuthLoginV2(
          loginMethod: AnalyticsAuthLoginV2LoginMethodEnum.email,
          sessionId: 'test',
        ), returnsNormally);
      });
      test('logAuthLogout constructs correctly', () {
        expect(() => analytics.logAuthLogout(
        ), returnsNormally);
      });
      test('logAuthPhoneLogin constructs correctly', () {
        expect(() => analytics.logAuthPhoneLogin(
          phoneCountry: 'test',
          trackingToken: 'test',
        ), returnsNormally);
      });
      test('logAuthSignup constructs correctly', () {
        expect(() => analytics.logAuthSignup(
          method: 'test',
        ), returnsNormally);
      });
      test('logAuthVerifyUser constructs correctly', () {
        expect(() => analytics.logAuthVerifyUser(
          localStatus: null,
          status: null,
        ), returnsNormally);
      });
    });
    group('purchase', () {
      test('logPurchaseCancelled constructs correctly', () {
        expect(() => analytics.logPurchaseCancelled(
          productId: 'test',
        ), returnsNormally);
      });
      test('logPurchaseCompleted constructs correctly', () {
        expect(() => analytics.logPurchaseCompleted(
          currencyCode: 'test',
          price: 42.0,
          productId: 'test',
          quantity: 42,
        ), returnsNormally);
      });
    });
    group('screen', () {
      test('logScreenLegacyView constructs correctly', () {
        expect(() => analytics.logScreenLegacyView(
          legacyScreenCode: 'test',
        ), returnsNormally);
      });
      test('logScreenView constructs correctly', () {
        expect(() => analytics.logScreenView(
          screenName: 'test',
        ), returnsNormally);
      });
    });
  });
}
