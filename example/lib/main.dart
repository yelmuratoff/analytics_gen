import 'package:analytics_gen/analytics_gen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/analytics/generated/analytics.dart';
import 'src/app/analytics_demo_controller.dart';
import 'src/app/app.dart';
import 'src/app/observable_analytics.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = HomeScreenController();
  final observableAnalytics = ObservableAnalytics(
    delegate: MockAnalyticsService(verbose: true),
    onRecord: controller.recordEvent,
  );

  Analytics.initialize(observableAnalytics);

  runApp(
    ChangeNotifierProvider<HomeScreenController>.value(
      value: controller,
      child: const AnalyticsExampleApp(),
    ),
  );
}
