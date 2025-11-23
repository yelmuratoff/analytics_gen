import 'package:analytics_gen/src/generator/generation_metadata.dart';
import 'package:analytics_gen/src/models/analytics_domain.dart';
import 'package:analytics_gen/src/models/analytics_event.dart';
import 'package:analytics_gen/src/models/analytics_parameter.dart';
import 'package:test/test.dart';

void main() {
  group('GenerationMetadata', () {
    final baseDomains = <String, AnalyticsDomain>{
      'b_purchase': AnalyticsDomain(
        name: 'b_purchase',
        events: [
          const AnalyticsEvent(
            name: 'completed',
            description: 'Purchase completed',
            parameters: [
              AnalyticsParameter(
                name: 'price',
                type: 'double',
                isNullable: false,
              ),
            ],
          ),
        ],
      ),
      'a_auth': AnalyticsDomain(
        name: 'a_auth',
        events: [
          const AnalyticsEvent(
            name: 'login',
            description: 'User login',
            parameters: [
              AnalyticsParameter(
                name: 'method',
                type: 'string',
                isNullable: false,
              ),
            ],
          ),
        ],
      ),
    };

    test('computes deterministic totals and fingerprint', () {
      final metadataA = GenerationMetadata.fromDomains(baseDomains);
      final metadataB = GenerationMetadata.fromDomains(
        Map<String, AnalyticsDomain>.from(baseDomains),
      );

      expect(metadataA.totalDomains, equals(2));
      expect(metadataA.totalEvents, equals(2));
      expect(metadataA.totalParameters, equals(2));
      expect(metadataA.fingerprint, metadataB.fingerprint);

      expect(
        metadataA.toJson(),
        containsPair('fingerprint', metadataA.fingerprint),
      );
    });

    test('updates fingerprint when event definition changes', () {
      final metadataOriginal = GenerationMetadata.fromDomains(baseDomains);

      final updatedDomains = <String, AnalyticsDomain>{
        ...baseDomains,
        'b_purchase': AnalyticsDomain(
          name: 'b_purchase',
          events: [
            const AnalyticsEvent(
              name: 'completed',
              description: 'Purchase completed v2',
              parameters: [
                AnalyticsParameter(
                  name: 'price',
                  type: 'double',
                  isNullable: false,
                ),
                AnalyticsParameter(
                  name: 'currency',
                  type: 'string',
                  isNullable: false,
                ),
              ],
            ),
          ],
        ),
      };

      final metadataUpdated = GenerationMetadata.fromDomains(updatedDomains);

      expect(metadataUpdated.totalParameters, equals(3));
      expect(metadataOriginal.fingerprint, isNot(metadataUpdated.fingerprint));
    });
  });
}
