import 'package:flutter/material.dart';

import 'home_screen.dart';

class AnalyticsExampleApp extends StatelessWidget {
  const AnalyticsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Analytics Gen Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
