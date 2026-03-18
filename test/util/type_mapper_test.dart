import 'package:analytics_gen/src/util/type_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('DartTypeMapper', () {
    test('maps "bool" to "bool"', () {
      expect(DartTypeMapper.toDartType('bool'), equals('bool'));
    });

    test('maps "boolean" to "bool"', () {
      expect(DartTypeMapper.toDartType('boolean'), equals('bool'));
    });

    test('maps "Boolean" to "bool" (case-insensitive)', () {
      expect(DartTypeMapper.toDartType('Boolean'), equals('bool'));
    });

    test('maps "BOOLEAN" to "bool" (case-insensitive)', () {
      expect(DartTypeMapper.toDartType('BOOLEAN'), equals('bool'));
    });

    test('maps standard types correctly', () {
      expect(DartTypeMapper.toDartType('int'), equals('int'));
      expect(DartTypeMapper.toDartType('string'), equals('String'));
      expect(DartTypeMapper.toDartType('float'), equals('double'));
      expect(DartTypeMapper.toDartType('double'), equals('double'));
      expect(DartTypeMapper.toDartType('number'), equals('num'));
      expect(DartTypeMapper.toDartType('datetime'), equals('DateTime'));
      expect(DartTypeMapper.toDartType('date'), equals('DateTime'));
      expect(DartTypeMapper.toDartType('uri'), equals('Uri'));
      expect(DartTypeMapper.toDartType('map'), equals('Map<String, dynamic>'));
      expect(DartTypeMapper.toDartType('list'), equals('List<dynamic>'));
    });

    test('returns original string for unknown types', () {
      expect(DartTypeMapper.toDartType('CustomType'), equals('CustomType'));
    });
  });
}
