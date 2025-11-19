import 'dart:io';

void main() async {
  final tempDir =
      Directory.systemTemp.createTempSync('analytics_gen_benchmark_');
  print('Running benchmark in ${tempDir.path}');

  try {
    // 1. Setup configuration
    final eventsDir = Directory('${tempDir.path}/events')..createSync();
    final outputDir = Directory('${tempDir.path}/lib/src/analytics/generated')
      ..createSync(recursive: true);
    Directory('${tempDir.path}/docs').createSync();
    Directory('${tempDir.path}/assets/generated').createSync(recursive: true);

    final configFile = File('${tempDir.path}/analytics_gen.yaml');
    configFile.writeAsStringSync('''
analytics_gen:
  events_path: events
  output_path: src/analytics/generated
  docs_path: docs/analytics_events.md
  exports_path: assets/generated
  generate_docs: true
  generate_csv: true
  generate_json: true
  generate_sql: true
  generate_plan: true
''');

    // Create pubspec.yaml
    File('${tempDir.path}/pubspec.yaml').writeAsStringSync('''
name: benchmark_project
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  analytics_gen:
    path: ${Directory.current.path}
''');

    print('Running pub get...');
    await Process.run('dart', ['pub', 'get'], workingDirectory: tempDir.path);

    // 2. Run scenarios
    print('\n| Events | Domains | Time (ms) | Files Generated |');
    print('|--------|---------|-----------|-----------------|');

    for (final totalEvents in [100, 500, 2000, 10000]) {
      final eventsPerDomain = 10;
      final domainCount = (totalEvents / eventsPerDomain).ceil();

      // Clean events dir
      if (eventsDir.existsSync()) eventsDir.deleteSync(recursive: true);
      eventsDir.createSync();

      // Generate YAMLs
      for (var i = 0; i < domainCount; i++) {
        final domainName = 'domain_$i';
        final buffer = StringBuffer();
        buffer.writeln('$domainName:');

        for (var j = 0; j < eventsPerDomain; j++) {
          buffer.writeln('  event_$j:');
          buffer.writeln('    description: Event $j in domain $i');
          buffer.writeln('    parameters:');
          buffer.writeln('      param_str: string');
          buffer.writeln('      param_int: int');
          buffer.writeln('      param_list: List<String>');
        }
        File('${eventsDir.path}/$domainName.yaml')
            .writeAsStringSync(buffer.toString());
      }

      // Run generator
      final stopwatch = Stopwatch()..start();
      final result = await Process.run(
        'dart',
        ['run', 'analytics_gen:generate', '--config', 'analytics_gen.yaml'],
        workingDirectory: tempDir.path,
      );
      stopwatch.stop();

      if (result.exitCode != 0) {
        print('Failed at $totalEvents events: ${result.stderr}');
        continue;
      }

      final generatedFiles =
          outputDir.listSync(recursive: true).whereType<File>().length;
      print(
          '| $totalEvents | $domainCount | ${stopwatch.elapsedMilliseconds} | $generatedFiles |');
    }
  } finally {
    print('Cleaning up...');
    tempDir.deleteSync(recursive: true);
  }
}
