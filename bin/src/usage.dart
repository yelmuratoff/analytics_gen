import 'package:args/args.dart';

void printUsage(ArgParser parser) {
  print('Analytics Gen - Code generator for type-safe analytics events');
  print('');
  print('Usage: dart run analytics_gen:generate [options]');
  print('');
  print('Options:');
  print(parser.usage);
  print('');
  print('Examples:');
  print('  # Generate code only');
  print('  dart run analytics_gen:generate');
  print('');
  print('  # Generate code and documentation');
  print('  dart run analytics_gen:generate --docs');
  print('');
  print('  # Generate everything');
  print('  dart run analytics_gen:generate --docs --exports');
  print('');
  print('  # Watch mode');
  print('  dart run analytics_gen:generate --watch');
  print('');
  print('  # Validate YAML only (no files written)');
  print('  dart run analytics_gen:generate --validate-only');
}
