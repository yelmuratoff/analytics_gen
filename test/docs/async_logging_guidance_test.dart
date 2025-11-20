import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Async logging documentation', () {
    test('README explains the synchronous default strategy', () {
      final readme = File('README.md').readAsStringSync();

      expect(
        readme,
        contains('Synchronous Logging & Async Providers'),
        reason: 'README should codify why logEvent stays synchronous.',
      );
      expect(
        readme,
        contains('QueueingAnalytics'),
        reason: 'README should include a queueing adapter example.',
      );
      expect(
        readme,
        contains('AsyncAnalyticsAdapter'),
        reason: 'README must point to AsyncAnalyticsAdapter for bridging.',
      );
      expect(
        readme,
        contains('Batch Logging Buffers'),
        reason: 'README should describe batch logging strategies.',
      );
      expect(
        readme,
        contains('BatchingAnalytics'),
        reason: 'README should mention the BatchingAnalytics helper.',
      );
    });

    test('Onboarding guide mentions AsyncAnalyticsAdapter usage', () {
      final onboarding = File('doc/ONBOARDING.md').readAsStringSync();

      expect(
        onboarding,
        contains('Logging stays synchronous by design'),
        reason:
            'Onboarding should explain the synchronous runtime assumptions.',
      );
      expect(
        onboarding,
        contains('AsyncAnalyticsAdapter'),
        reason: 'Onboarding should reference AsyncAnalyticsAdapter for queues.',
      );
      expect(
        onboarding,
        contains('BatchingAnalytics'),
        reason: 'Onboarding should highlight batch buffering hooks.',
      );
    });
  });

  group('Async logging example', () {
    test('example app demonstrates AsyncAnalyticsAdapter', () {
      final example = File('example/lib/main.dart').readAsStringSync();

      expect(
        example,
        contains('AsyncAnalyticsAdapter'),
        reason: 'Example should import/use AsyncAnalyticsAdapter.',
      );
      expect(
        example,
        contains('logEventAsync'),
        reason: 'Example should call logEventAsync to show awaiting patterns.',
      );
    });
  });
}
