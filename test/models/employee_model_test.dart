import 'package:flutter_test/flutter_test.dart';
import 'package:storepro/models/employee_model.dart';

void main() {
  group('EmployeeModel', () {
    test('fromMap and toMap roundtrip correctly', () {
      const original = EmployeeModel(
        id: 'emp_001',
        storeId: 'store_001',
        name: 'Maria Santos',
        pin: '1234',
        createdAt: '2026-01-15',
        updatedAt: '2026-06-01',
      );
      final map = original.toMap();
      final restored = EmployeeModel.fromMap(map);
      expect(restored.name, equals('Maria Santos'));
      expect(restored.pin, equals('1234'));
    });

    test('fromMap uses defaults when keys are missing', () {
      final result = EmployeeModel.fromMap({
        'id': 'e1', 'storeId': 's1', 'name': 'Juan',
        'createdAt': '', 'updatedAt': '',
      });
      expect(result.pin, equals(''));
    });

    test('toSql and fromSql roundtrip correctly', () {
      const original = EmployeeModel(
        id: 'emp_002',
        storeId: 'store_001',
        name: 'Pedro Reyes',
        pin: '5678',
        createdAt: '2026-02-01',
        updatedAt: '2026-06-01',
      );
      final sqlMap = original.toSql();
      final restored = EmployeeModel.fromSql(sqlMap);
      expect(restored.name, equals('Pedro Reyes'));
      expect(restored.pin, equals('5678'));
    });

    test('copyWith updates only specified fields', () {
      const employee = EmployeeModel(
        id: 'emp_001', storeId: 'store_001', name: 'Maria Santos',
        createdAt: '2026-01-15', updatedAt: '2026-06-01',
      );
      final copied = employee.copyWith(pin: '4321');
      expect(copied.pin, equals('4321'));
      expect(copied.name, equals('Maria Santos'));
      expect(copied.id, equals('emp_001'));
    });
  });
}
