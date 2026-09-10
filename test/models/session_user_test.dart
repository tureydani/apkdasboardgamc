import 'package:flutter_test/flutter_test.dart';
import 'package:sosapk/models/session_user.dart';

void main() {
  group('SessionUser.fromJson', () {
    test('parsea un usuario institucional completo', () {
      final user = SessionUser.fromJson({
        'id': '3',
        'email': 'admin@bomberos.bo',
        'phoneNumber': null,
        'firstName': 'Juan',
        'lastName': 'Bombero',
        'role': 'INSTITUTION',
        'privilegeCode': 'INSTITUTION_ADMIN',
        'privilegeName': 'Administrador de Institución',
        'institutionId': 2,
        'subinstitutionId': null,
      });

      expect(user.id, '3');
      expect(user.fullName, 'Juan Bombero');
      expect(user.role, 'INSTITUTION');
      expect(user.institutionId, 2);
      expect(user.subinstitutionId, isNull);
    });

    test('rellena valores por defecto cuando faltan campos', () {
      final user = SessionUser.fromJson({'id': 10});

      expect(user.id, '10');
      expect(user.firstName, '');
      expect(user.lastName, '');
      expect(user.fullName, '');
      expect(user.role, 'INSTITUTION');
      expect(user.privilegeCode, isNull);
      expect(user.institutionId, isNull);
    });

    test('isCentral es true solo para privilegios de Central', () {
      for (final code in ['CENTRAL_ADMIN', 'CENTRAL_OPERATOR', 'DISPATCHER']) {
        final user = SessionUser.fromJson({'id': '1', 'firstName': 'a', 'lastName': 'b', 'privilegeCode': code});
        expect(user.isCentral, isTrue, reason: code);
      }
      final institutionUser = SessionUser.fromJson({
        'id': '1',
        'firstName': 'a',
        'lastName': 'b',
        'privilegeCode': 'INSTITUTION_OPERATOR',
      });
      expect(institutionUser.isCentral, isFalse);
    });

    test('isAdmin es true para CENTRAL_ADMIN e INSTITUTION_ADMIN', () {
      final centralAdmin = SessionUser.fromJson({'id': '1', 'firstName': 'a', 'lastName': 'b', 'privilegeCode': 'CENTRAL_ADMIN'});
      final institutionAdmin = SessionUser.fromJson({'id': '2', 'firstName': 'a', 'lastName': 'b', 'privilegeCode': 'INSTITUTION_ADMIN'});
      final operator = SessionUser.fromJson({'id': '3', 'firstName': 'a', 'lastName': 'b', 'privilegeCode': 'INSTITUTION_OPERATOR'});

      expect(centralAdmin.isAdmin, isTrue);
      expect(institutionAdmin.isAdmin, isTrue);
      expect(operator.isAdmin, isFalse);
    });
  });
}
