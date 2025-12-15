// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import
// ignore_for_file: directives_ordering, unnecessary_string_interpolations
// coverage:ignore-file

import 'package:analytics_gen/analytics_gen.dart';
import 'package:analytics_gen_example/models.dart';

/// Generated mixin for purchase analytics events
mixin AnalyticsPurchase on AnalyticsBase {
  /// User cancelled a purchase
  ///
  /// Parameters:
  /// - `product_id`: String
  /// - `reason`: String? - Reason for cancellation
  void logPurchaseCancelled({
    required String productId,
    String? reason,
    Map<String, Object?>? parameters,
  }) {
    final eventParameters =
        parameters ??
        <String, Object?>{
          'description': 'User cancelled a purchase',
          "product_id": productId,
          if (reason != null) "reason": reason,
        };

    logger.logEvent(
      name: "purchase_flow_cancelled",
      parameters: eventParameters,
    );
  }

  /// User completed a purchase
  ///
  /// Parameters:
  /// - `currency-code`: String
  /// - `amount_value`: double - Localized amount used by legacy dashboards
  /// - `product_id`: String
  /// - `quantity`: int - Number of items purchased
  void logPurchaseCompleted({
    required String currencyCode,
    required double price,
    required String productId,
    required int quantity,
    Map<String, Object?>? parameters,
  }) {
    final eventParameters =
        parameters ??
        <String, Object?>{
          'description': 'User completed a purchase',
          "currency-code": currencyCode,
          "amount_value": price,
          "product_id": productId,
          "quantity": quantity,
        };

    logger.logEvent(
      name: "purchase_flow_completed",
      parameters: eventParameters,
    );
  }
}
