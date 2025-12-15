import 'package:analytics_gen/src/models/analytics_parameter.dart';

import '../../util/string_utils.dart';
import '../../util/type_mapper.dart';
import 'base_renderer.dart';
import 'sub_renderers/validation_renderer.dart';

/// Renders context capability interfaces and mixins.
class ContextRenderer extends BaseRenderer {
  /// Creates a new context renderer.
  const ContextRenderer();

  /// Renders a context capability file.
  String renderContextFile(
    String contextName,
    List<AnalyticsParameter> properties,
  ) {
    final pascalName = StringUtils.capitalizePascal(contextName);
    final camelContextName = StringUtils.toCamelCase(contextName);

    final buffer = StringBuffer();
    buffer.write(renderFileHeader(includeCoverageIgnore: false));
    buffer.write(renderImports(['package:analytics_gen/analytics_gen.dart']));

    buffer.writeln('/// Capability interface for $pascalName');
    buffer.writeln(
        'abstract class ${pascalName}Capability implements AnalyticsCapability {');

    // Collect all unique operations used across properties
    final operations = <String>{};
    for (final prop in properties) {
      final propOps = prop.operations ?? ['set'];
      operations.addAll(propOps);
    }

    // Generate interface methods for each operation
    for (final op in operations.toList()..sort()) {
      final normalizedOp = StringUtils.toCamelCase(op);
      final interfaceMethodName = '$normalizedOp${pascalName}Property';
      buffer
          .writeln('  void $interfaceMethodName(String name, Object? value);');
    }
    buffer.writeln('}');
    buffer.writeln();

    buffer.writeln('/// Key for $pascalName capability');
    buffer.writeln(
        "const ${camelContextName}Key = CapabilityKey<${pascalName}Capability>('$contextName');");
    buffer.writeln();

    buffer.writeln('/// Mixin for Analytics class');
    buffer.writeln('mixin Analytics$pascalName on AnalyticsBase {');

    for (final prop in properties) {
      final camelName = StringUtils.toCamelCase(prop.codeName);
      final propOps = prop.operations ?? ['set'];

      for (final op in propOps) {
        final normalizedOp = StringUtils.toCamelCase(op);
        final methodName =
            '$normalizedOp$pascalName${StringUtils.capitalizePascal(camelName)}';
        final interfaceMethodName = '$normalizedOp${pascalName}Property';

        final dartType = DartTypeMapper.toDartType(prop.type);
        final nullableType = prop.isNullable ? '$dartType?' : dartType;

        if (prop.description != null) {
          buffer.writeln('  /// ${prop.description}');
        }
        buffer.writeln('  void $methodName($nullableType value) {');

        if (prop.allowedValues != null && prop.allowedValues!.isNotEmpty) {
          const validator = ValidationRenderer();
          final constName =
              'allowed${StringUtils.capitalizePascal(camelName)}Values';
          final encodedValues =
              validator.encodeAllowedValues(prop.allowedValues!);
          final joinedValues = validator.joinAllowedValues(prop.allowedValues!);

          buffer.write(validator.renderAllowedValuesCheck(
            camelParam: 'value',
            constName: constName,
            encodedValues: encodedValues,
            joinedValues: joinedValues,
            isNullable: prop.isNullable,
            type: dartType,
          ));
        }

        buffer.writeln(
            "    capability(${camelContextName}Key)?.$interfaceMethodName('${prop.name}', value);");
        buffer.writeln('  }');
        buffer.writeln();
      }
    }

    buffer.writeln('}');

    return buffer.toString();
  }
}
