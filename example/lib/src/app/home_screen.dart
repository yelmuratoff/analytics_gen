import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'analytics_demo_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeScreenController>();
    final events = controller.events;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Gen – Demo'),
        actions: [
          IconButton(
            tooltip: 'Clear log',
            icon: const Icon(Icons.delete),
            onPressed: controller.events.isEmpty
                ? null
                : () => context.read<HomeScreenController>().clearLog(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Try the generated analytics API:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => context
                      .read<HomeScreenController>()
                      .authenticateReturningUser(),
                  child: const Text('Authenticate returning user'),
                ),
                ElevatedButton(
                  onPressed: () => context
                      .read<HomeScreenController>()
                      .completeInviteSignup(),
                  child: const Text('Complete invite signup'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      context.read<HomeScreenController>().showHomeDashboard(),
                  child: const Text('Show home dashboard'),
                ),
                ElevatedButton(
                  onPressed: () => context
                      .read<HomeScreenController>()
                      .purchaseMonthlySubscription(),
                  child: const Text('Purchase monthly plan'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      context.read<HomeScreenController>().toggleTheme(),
                  child: const Text('Set Theme Context'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      context.read<HomeScreenController>().setUserProperties(),
                  child: const Text('Set User Properties'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Event Log',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Divider(),
            Expanded(
              child: events.isEmpty
                  ? const Center(
                      child: Text('Tap any button above to log events.'),
                    )
                  : ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final entry = events[index];
                        final paramsString = entry.parameters.isEmpty
                            ? 'No parameters'
                            : entry.parameters.entries
                                  .map((e) => '${e.key}=${e.value}')
                                  .join(', ');
                        return ListTile(
                          title: Text(entry.name),
                          subtitle: Text(
                            '${entry.timestamp.toIso8601String()}\n$paramsString',
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
