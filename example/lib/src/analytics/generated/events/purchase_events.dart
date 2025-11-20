// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated at: 2025-11-20T16:55:12.828050
// ignore_for_file: type=lint, unused_import
// ignore_for_file: directives_ordering, unnecessary_string_interpolations
// coverage:ignore-file

import 'package:analytics_gen/analytics_gen.dart';

/// Generated mixin for purchase analytics events
mixin AnalyticsPurchase on AnalyticsBase {
  /// User cancelled a purchase
  ///
  /// Parameters:
  /// - `product_id`: string
  /// - `reason`: string? - Reason for cancellation
  void logPurchaseCancelled({
    required String productId,
    String? reason,
  }) {

    logger.logEvent(
      name: "Purchase Flow: cancelled",
      parameters: <String, Object?>{
        'description': 'User cancelled a purchase',
        "product_id": productId,
        if (reason != null) "reason": reason,
      },
    );
  }

  /// User completed a purchase
  ///
  /// Parameters:
  /// - `currency-code`: string
  /// - `amount_value`: double - Localized amount used by legacy dashboards
  /// - `product_id`: string
  /// - `quantity`: int - Number of items purchased
  void logPurchaseCompleted({
    required String currencyCode,
    required double price,
    required String productId,
    required int quantity,
  }) {

    logger.logEvent(
      name: "Purchase Flow: completed",
      parameters: <String, Object?>{
        'description': 'User completed a purchase',
        "currency-code": currencyCode,
        "amount_value": price,
        "product_id": productId,
        "quantity": quantity,
      },
    );
  }

}
