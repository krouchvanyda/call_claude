import 'package:erp_mobile/features/auth/entities/user.dart';
import 'package:test/test.dart';

const _alice = User(
  id: 'u-1',
  email: 'alice@example.com',
  displayName: 'Alice',
  roles: {'admin', 'finance.invoice.create'},
);

void main() {
  group('User', () {
    test('two instances with the same fields are equal (freezed)', () {
      const a = User(
        id: 'u-1',
        email: 'alice@example.com',
        displayName: 'Alice',
        roles: {'admin'},
      );
      const b = User(
        id: 'u-1',
        email: 'alice@example.com',
        displayName: 'Alice',
        roles: {'admin'},
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('roles default to an empty set when omitted', () {
      const u = User(
        id: 'u-1',
        email: 'a@b.co',
        displayName: 'A',
      );
      expect(u.roles, isEmpty);
    });

    group('hasRole', () {
      test('returns true when the role is present', () {
        expect(_alice.hasRole('admin'), isTrue);
        expect(_alice.hasRole('finance.invoice.create'), isTrue);
      });

      test('returns false when the role is absent', () {
        expect(_alice.hasRole('hr.payroll.read'), isFalse);
      });

      test('returns false on an empty role set', () {
        const u = User(id: 'u', email: 'a@b.co', displayName: 'A');
        expect(u.hasRole('admin'), isFalse);
      });
    });

    group('hasAnyRole', () {
      test('true when at least one wanted role is held', () {
        expect(_alice.hasAnyRole(['hr.payroll.read', 'admin']), isTrue);
      });

      test('false when none of the wanted roles is held', () {
        expect(_alice.hasAnyRole(['hr.payroll.read', 'sales.read']), isFalse);
      });

      test('false on empty wanted iterable (vacuous-truth-free)', () {
        expect(_alice.hasAnyRole(const <String>[]), isFalse);
      });
    });

    group('hasAllRoles', () {
      test('true when every required role is held', () {
        expect(
          _alice.hasAllRoles(['admin', 'finance.invoice.create']),
          isTrue,
        );
      });

      test('false when any required role is missing', () {
        expect(
          _alice.hasAllRoles(['admin', 'hr.payroll.read']),
          isFalse,
        );
      });

      test('true on empty required iterable (vacuous truth)', () {
        expect(_alice.hasAllRoles(const <String>[]), isTrue);
      });
    });

    test('copyWith preserves untouched fields', () {
      final renamed = _alice.copyWith(displayName: 'Alice Smith');
      expect(renamed.id, _alice.id);
      expect(renamed.email, _alice.email);
      expect(renamed.roles, _alice.roles);
      expect(renamed.displayName, 'Alice Smith');
    });
  });
}
