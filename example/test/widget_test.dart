import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:analytics_gen/analytics_gen.dart';

import 'package:analytics_gen_example/src/app/analytics_demo_controller.dart';
import 'package:analytics_gen_example/src/app/app.dart';
import 'package:analytics_gen_example/src/app/observable_analytics.dart';
import 'package:analytics_gen_example/src/analytics/generated/analytics.dart';

void main() {
  testWidgets('buttons log events via generated API', (tester) async {
    final controller = HomeScreenController();
    final observableAnalytics = ObservableAnalytics(
      delegate: MockAnalyticsService(),
      onRecord: controller.recordEvent,
    );
    Analytics.initialize(observableAnalytics);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const AnalyticsExampleApp(),
      ),
    );

    await tester.tap(find.text('Authenticate returning user'));
    await tester.pump();

    expect(controller.events.length, 1);
    expect(controller.events.first.name, 'auth: login');
  });
}
