// GENERATED CODE - DO NOT MODIFY BY HAND
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
      name: "purchase: cancelled",
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
  /// - `currency`: string
  /// - `price`: double
  /// - `product_id`: string
  /// - `quantity`: int - Number of items purchased
  void logPurchaseCompleted({
    required String currency,
    required double price,
    required String productId,
    required int quantity,
  }) {

    logger.logEvent(
      name: "purchase: completed",
      parameters: <String, Object?>{
        'description': 'User completed a purchase',
        "currency": currency,
        "price": price,
        "product_id": productId,
        "quantity": quantity,
      },
    );
  }

}
