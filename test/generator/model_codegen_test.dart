import 'package:analytics_gen/src/generator/model_codegen.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:test/test.dart';

void main() {
  group('ParameterCodegen.usesGeneratedEnum', () {
    AnalyticsParameter param({
      String type = 'string',
      List<Object>? allowedValues = const ['a'],
      String? dartType,
    }) =>
        AnalyticsParameter(
          name: 'method',
          type: type,
          isNullable: false,
          allowedValues: allowedValues,
          dartType: dartType,
        );

    test('is true for a lowercase string with allowed values', () {
      expect(param().usesGeneratedEnum, isTrue);
    });

    test('is false for a capitalized String type', () {
      expect(param(type: 'String').usesGeneratedEnum, isFalse);
    });

    test('is false without allowed values', () {
      expect(param(allowedValues: null).usesGeneratedEnum, isFalse);
      expect(param(allowedValues: const []).usesGeneratedEnum, isFalse);
    });

    test('is false when dart_type supplies the Dart type', () {
      expect(param(dartType: 'LoginMethod').usesGeneratedEnum, isFalse);
    });
  });

  group('EventCodegen.parametersArgumentName', () {
    AnalyticsEvent event(String parameterIdentifier) => AnalyticsEvent(
          name: 'login',
          description: 'Login',
          parameters: [
            AnalyticsParameter(
              name: parameterIdentifier,
              type: 'string',
              isNullable: false,
            ),
          ],
        );

    test('is parameters by default', () {
      expect(event('method').parametersArgumentName, 'parameters');
    });

    test('avoids a clash with an event parameter named parameters', () {
      expect(event('parameters').parametersArgumentName, 'analyticsParameters');
    });
  });
}
