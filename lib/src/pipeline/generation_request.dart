import 'package:analytics_gen/src/util/logger.dart';

/// Request to generate analytics code.
class GenerationRequest {
  /// Creates a new generation request.
  const GenerationRequest({
    required this.generateCode,
    required this.generateDocs,
    required this.generateExports,
    required this.verbose,
    this.logger = const NoOpLogger(),
  });

  /// Whether to generate Dart code.
  final bool generateCode;

  /// Whether to generate documentation.
  final bool generateDocs;

  /// Whether to generate export files.
  final bool generateExports;

  /// Whether to enable verbose logging.
  final bool verbose;

  /// The logger to use.
  final Logger logger;

  /// Whether to generate any artifacts.
  bool get hasArtifacts => generateCode || generateDocs || generateExports;
}
