import 'package:analytics_gen/src/util/logger.dart';

class GenerationRequest {
  const GenerationRequest({
    required this.generateCode,
    required this.generateDocs,
    required this.generateExports,
    required this.verbose,
    this.logger = const NoOpLogger(),
  });

  final bool generateCode;
  final bool generateDocs;
  final bool generateExports;
  final bool verbose;
  final Logger logger;

  bool get hasArtifacts => generateCode || generateDocs || generateExports;
}
