// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import
// ignore_for_file: directives_ordering, unnecessary_string_interpolations
// coverage:ignore-file

import 'package:analytics_gen/analytics_gen.dart';

/// Generated mixin for purchase analytics events
mixin AnalyticsPurchase on AnalyticsBase {
  /// User completed a purchase
  ///
  /// Parameters:
  /// - `product_id`: string
  /// - `price`: double
  /// - `currency`: string
  /// - `quantity`: int - Number of items purchased
  void logPurchaseCompleted({
    required String productId,
    required double price,
    required String currency,
    required int quantity,
  }) {
    logger.logEvent(
      name: "purchase: completed",
      parameters: <String, Object?>{
        "product_id": productId,
        "price": price,
        "currency": currency,
        "quantity": quantity,
      },
    );
  }

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
        "product_id": productId,
        if (reason != null) "reason": reason,
      },
    );
  }

}
