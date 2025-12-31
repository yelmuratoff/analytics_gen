// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, deprecated_member_use_from_same_package
// ignore_for_file: directives_ordering, unnecessary_string_interpolations
// coverage:ignore-file

import 'package:analytics_gen/analytics_gen.dart';
import 'package:analytics_gen_example/models.dart';

/// Enum for purchase_completed - currency
enum AnalyticsCommercePurchaseCompletedCurrencyEnum {
  usd('USD'),
  eur('EUR'),
  gbp('GBP');

  final String value;
  const AnalyticsCommercePurchaseCompletedCurrencyEnum(this.value);
}

/// Generated mixin for commerce analytics events
mixin AnalyticsCommerce on AnalyticsBase {
  /// Triggered when a user completes a payment.
  ///
  /// Parameters:
  /// - `currency`: AnalyticsCommercePurchaseCompletedCurrencyEnum
  /// - `items_count`: int
  /// - `transaction_id`: String
  /// - `value`: double
  void logCommercePurchaseCompleted({
    required AnalyticsCommercePurchaseCompletedCurrencyEnum currency,
    required int itemsCount,
    required String transactionId,
    required double value,
    Map<String, Object?>? parameters,
  }) {
    if (transactionId.length < 10) {
      throw ArgumentError.value(
        transactionId,
        'transactionId',
        'length must be at least 10',
      );
    }

    if (value < 0.01) {
      throw ArgumentError.value(value, 'value', 'must be at least 0.01');
    }

    final eventParameters = <String, Object?>{
      'description': 'Triggered when a user completes a payment.',
      "currency": currency.value,
      "items_count": itemsCount,
      "transaction_id": transactionId,
      "value": value,
    }..addAll(parameters ?? const {});

    logger.logEvent(
      name: "commerce_purchase_completed",
      parameters: eventParameters,
    );
  }
}
