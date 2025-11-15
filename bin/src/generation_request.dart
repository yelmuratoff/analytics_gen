typedef Logger = void Function(String message);

class GenerationRequest {
  const GenerationRequest({
    required this.generateCode,
    required this.generateDocs,
    required this.generateExports,
    required this.verbose,
  });

  final bool generateCode;
  final bool generateDocs;
  final bool generateExports;
  final bool verbose;

  Logger? get logger => verbose ? (message) => print(message) : null;

  bool get hasArtifacts => generateCode || generateDocs || generateExports;
}
