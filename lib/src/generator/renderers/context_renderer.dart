import '../../models/analytics_event.dart';
import '../../util/string_utils.dart';
import '../../util/type_mapper.dart';
import 'base_renderer.dart';

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

    final interfaceMethodName = 'set${pascalName}Property';

    buffer.writeln('  void $interfaceMethodName(String name, Object? value);');
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

      final methodName =
          'set$pascalName${StringUtils.capitalizePascal(camelName)}';

      final dartType = DartTypeMapper.toDartType(prop.type);
      final nullableType = prop.isNullable ? '$dartType?' : dartType;

      if (prop.description != null) {
        buffer.writeln('  /// ${prop.description}');
      }
      buffer.writeln('  void $methodName($nullableType value) {');

      if (prop.allowedValues != null && prop.allowedValues!.isNotEmpty) {
        final constName =
            'allowed${StringUtils.capitalizePascal(camelName)}Values';
        final encodedValues = encodeAllowedValues(prop.allowedValues!);
        final joinedValues = joinAllowedValues(prop.allowedValues!);

        buffer.write(renderAllowedValuesCheck(
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

    buffer.writeln('}');

    return buffer.toString();
  }
}
