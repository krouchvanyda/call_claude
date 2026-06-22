import 'package:erp_mobile/features/auth/entities/permission.dart';
import 'package:erp_mobile/features/auth/entities/role.dart';
import 'package:test/test.dart';

void main() {
  group('Role', () {
    test('default permissions set is empty', () {
      const role = Role(name: 'newbie');
      expect(role.permissions, isEmpty);
    });

    test('grants delegates to its permission set (exact match)', () {
      final role = Role(
        name: 'accountant',
        permissions: {
          const Permission(token: 'finance.invoice.create'),
          const Permission(token: 'finance.invoice.read'),
        },
      );
      expect(
        role.grants(const Permission(token: 'finance.invoice.create')),
        isTrue,
      );
      expect(
        role.grants(const Permission(token: 'finance.invoice.approve')),
        isFalse,
      );
    });

    test('grants honours wildcard semantics through PermissionSetMatching',
        () {
      final role = Role(
        name: 'finance-admin',
        permissions: {const Permission(token: 'finance.*')},
      );
      expect(
        role.grants(const Permission(token: 'finance.invoice.create')),
        isTrue,
      );
      expect(
        role.grants(const Permission(token: 'inventory.stock.read')),
        isFalse,
      );
    });

    test('two Roles with the same name and permissions are equal (freezed)',
        () {
      final a = Role(
        name: 'r',
        permissions: {const Permission(token: 'a.b')},
      );
      final b = Role(
        name: 'r',
        permissions: {const Permission(token: 'a.b')},
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
