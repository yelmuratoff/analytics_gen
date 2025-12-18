import 'package:analytics_gen/src/models/analytics_event.dart';

import '../../../util/type_mapper.dart';
import '../enum_renderer.dart';

/// Renders documentation comments.
class DocumentationRenderer {
  /// Creates a new documentation renderer.
  const DocumentationRenderer();

  /// Renders a documentation comment block.
  String renderDocComment(String comment, {int indent = 0}) {
    if (comment.isEmpty) return '';

    final indentStr = '  ' * indent;
    final buffer = StringBuffer();
    final lines = comment.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) {
        buffer.writeln('$indentStr///');
      } else {
        buffer.writeln('$indentStr/// $line');
      }
    }

    return buffer.toString();
  }

  /// Renders documentation for an analytics event.
  String renderEventDocs(
    String domainName,
    AnalyticsEvent event, {
    int indent = 0,
  }) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;

    buffer.write(renderDocComment(event.description, indent: indent));
    buffer.writeln('$indentStr///');

    if (event.parameters.isNotEmpty) {
      buffer.writeln('$indentStr/// Parameters:');
      for (final param in event.parameters) {
        final isEnum = param.type == 'string' &&
            param.allowedValues != null &&
            param.allowedValues!.isNotEmpty;

        String typeName;
        if (param.dartType != null) {
          typeName = param.dartType!;
        } else {
          typeName = isEnum
              ? const EnumRenderer().buildEnumName(domainName, event, param)
              : DartTypeMapper.toDartType(param.type);
        }

        if (param.description != null) {
          buffer.writeln(
            '$indentStr/// - `${param.name}`: $typeName${param.isNullable ? '?' : ''} - ${param.description}',
          );
        } else {
          buffer.writeln(
            '$indentStr/// - `${param.name}`: $typeName${param.isNullable ? '?' : ''}',
          );
        }
      }
    }

    return buffer.toString();
  }
}
