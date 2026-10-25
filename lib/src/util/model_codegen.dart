import '../models/analytics_event.dart';
import '../models/analytics_parameter.dart';
import 'string_utils.dart';

/// How code generation treats an [AnalyticsParameter].
extension ParameterCodegen on AnalyticsParameter {
  /// Whether the generated API types this parameter as a generated enum.
  ///
  /// Only a lowercase `string` parameter with `allowed_values` and no
  /// `dart_type` gets one; other types validate the values at runtime.
  bool get usesGeneratedEnum =>
      dartType == null &&
      type == 'string' &&
      (allowedValues?.isNotEmpty ?? false);
}

/// How code generation names the members of an [AnalyticsEvent] method.
extension EventCodegen on AnalyticsEvent {
  /// The name of the generated method's extra parameters map argument.
  ///
  /// It is `parameters` unless an event parameter already uses that name.
  String get parametersArgumentName =>
      parameters.any((p) => StringUtils.toCamelCase(p.codeName) == 'parameters')
          ? 'analyticsParameters'
          : 'parameters';
}
