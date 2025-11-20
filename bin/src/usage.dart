import 'package:analytics_gen/src/util/logger.dart';
import 'package:args/args.dart';

void printUsage(ArgParser parser, {Logger? logger}) {
  final log = logger ?? const ConsoleLogger();
  log.info('Analytics Gen - Code generator for type-safe analytics events');
  log.info('');
  log.info('Usage: dart run analytics_gen:generate [options]');
  log.info('');
  log.info('Options:');
  log.info(parser.usage);
  log.info('');
  log.info('Examples:');
  log.info('  # Generate code only');
  log.info('  dart run analytics_gen:generate');
  log.info('');
  log.info('  # Generate code and documentation');
  log.info('  dart run analytics_gen:generate --docs');
  log.info('');
  log.info('  # Generate everything');
  log.info('  dart run analytics_gen:generate --docs --exports');
  log.info('');
  log.info('  # Watch mode');
  log.info('  dart run analytics_gen:generate --watch');
  log.info('');
  log.info('  # Validate YAML only (no files written)');
  log.info('  dart run analytics_gen:generate --validate-only');
}
