import '../../models/analytics_event.dart';
import '../../util/string_utils.dart';
import '../../util/type_mapper.dart';

class ContextRenderer {
  String renderContextFile(
    String contextName,
    List<AnalyticsParameter> properties,
  ) {
    final pascalName = StringUtils.capitalizePascal(contextName);
    final camelContextName = StringUtils.toCamelCase(contextName);

    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// ignore_for_file: type=lint, unused_import');
    buffer.writeln();
    buffer.writeln("import 'package:analytics_gen/analytics_gen.dart';");
    buffer.writeln();

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
        final encodedValues = prop.allowedValues!
            .map((value) => '\'${StringUtils.escapeSingleQuoted(value)}\'')
            .join(', ');
        final joinedValues = prop.allowedValues!.join(', ');

        buffer.write(_renderAllowedValuesCheck(
          camelParam: 'value',
          constName: constName,
          encodedValues: encodedValues,
          joinedValues: joinedValues,
          isNullable: prop.isNullable,
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

  String _renderAllowedValuesCheck({
    required String camelParam,
    required String constName,
    required String encodedValues,
    required String joinedValues,
    required bool isNullable,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('    const $constName = <String>{$encodedValues};');

    final condition = isNullable
        ? 'if ($camelParam != null && !$constName.contains($camelParam)) {'
        : 'if (!$constName.contains($camelParam)) {';

    buffer.writeln('    $condition');
    buffer.writeln('      throw ArgumentError.value(');
    buffer.writeln('        $camelParam,');
    buffer.writeln("        '$camelParam',");
    buffer.writeln("        'must be one of $joinedValues',");
    buffer.writeln('      );');
    buffer.writeln('    }');
    return buffer.toString();
  }
}
