import 'package:erp_mobile/features/auth/entities/permission.dart';
import 'package:test/test.dart';

void main() {
  group('Permission — parsing & segment access', () {
    test('parse trims surrounding whitespace', () {
      expect(Permission.parse('  finance.invoice.create  ').token,
          'finance.invoice.create');
    });

    test('feature returns the first dotted segment', () {
      expect(const Permission(token: 'finance.invoice.create').feature,
          'finance');
      expect(const Permission(token: 'admin').feature, 'admin');
    });

    test('entity returns the second segment when present, else null', () {
      expect(const Permission(token: 'finance.invoice.create').entity,
          'invoice');
      expect(const Permission(token: 'admin').entity, isNull);
    });

    test('action returns the third segment when present, else null', () {
      expect(const Permission(token: 'finance.invoice.create').action,
          'create');
      expect(const Permission(token: 'finance.invoice').action, isNull);
      expect(const Permission(token: 'admin').action, isNull);
    });

    test('feature is empty string for an empty token (defensive)', () {
      expect(const Permission(token: '').feature, '');
    });

    test('hasWildcard detects any "*" in the token', () {
      expect(const Permission(token: '*').hasWildcard, isTrue);
      expect(const Permission(token: 'finance.*').hasWildcard, isTrue);
      expect(const Permission(token: 'finance.*.read').hasWildcard, isTrue);
      expect(const Permission(token: 'finance.invoice.create').hasWildcard,
          isFalse);
    });
  });

  group('Permission.grants — exact match (no wildcards)', () {
    test('identical tokens grant', () {
      const held = Permission(token: 'finance.invoice.create');
      const need = Permission(token: 'finance.invoice.create');
      expect(held.grants(need), isTrue);
    });

    test('different actions do not grant', () {
      const held = Permission(token: 'finance.invoice.read');
      const need = Permission(token: 'finance.invoice.create');
      expect(held.grants(need), isFalse);
    });

    test('different entities do not grant', () {
      const held = Permission(token: 'finance.report.read');
      const need = Permission(token: 'finance.invoice.read');
      expect(held.grants(need), isFalse);
    });

    test('different features do not grant', () {
      const held = Permission(token: 'inventory.invoice.read');
      const need = Permission(token: 'finance.invoice.read');
      expect(held.grants(need), isFalse);
    });

    test('held shorter than required does not grant (no inferred wildcard)',
        () {
      const held = Permission(token: 'finance.invoice');
      const need = Permission(token: 'finance.invoice.create');
      expect(held.grants(need), isFalse);
    });

    test('held longer than required does not grant', () {
      const held = Permission(token: 'finance.invoice.create.extra');
      const need = Permission(token: 'finance.invoice.create');
      expect(held.grants(need), isFalse);
    });
  });

  group('Permission.grants — trailing star ("rest matches")', () {
    test('feature.* grants any sub-permission', () {
      const held = Permission(token: 'finance.*');
      expect(held.grants(const Permission(token: 'finance.invoice.create')),
          isTrue);
      expect(held.grants(const Permission(token: 'finance.report.export')),
          isTrue);
    });

    test('feature.entity.* grants any action under the entity', () {
      const held = Permission(token: 'finance.invoice.*');
      expect(held.grants(const Permission(token: 'finance.invoice.create')),
          isTrue);
      expect(held.grants(const Permission(token: 'finance.invoice.read')),
          isTrue);
    });

    test('does not cross feature boundaries', () {
      const held = Permission(token: 'finance.*');
      expect(held.grants(const Permission(token: 'inventory.invoice.read')),
          isFalse);
    });

    test('trailing star requires at least one continuation segment', () {
      // `finance.*` is "finance plus something" — bare `finance` does NOT
      // match because the held pattern explicitly demands more after the
      // dot.
      const held = Permission(token: 'finance.*');
      expect(held.grants(const Permission(token: 'finance')), isFalse);
    });
  });

  group('Permission.grants — mid-star (single-segment match)', () {
    test('feature.*.action grants when action matches and entity is a single segment',
        () {
      const held = Permission(token: 'finance.*.read');
      expect(held.grants(const Permission(token: 'finance.invoice.read')),
          isTrue);
      expect(held.grants(const Permission(token: 'finance.report.read')),
          isTrue);
    });

    test('feature.*.action does NOT grant a different action', () {
      const held = Permission(token: 'finance.*.read');
      expect(held.grants(const Permission(token: 'finance.invoice.create')),
          isFalse);
    });

    test('mid-star is exactly one segment (no nested dots)', () {
      const held = Permission(token: 'finance.*.read');
      // `finance.invoice.subitem.read` has TWO segments where the star
      // expects one — must not match.
      expect(
        held.grants(const Permission(token: 'finance.invoice.subitem.read')),
        isFalse,
      );
    });
  });

  group('Permission.grants — bare-star super-admin', () {
    test('"*" grants any non-empty token', () {
      const held = Permission(token: '*');
      expect(held.grants(const Permission(token: 'finance.invoice.create')),
          isTrue);
      expect(held.grants(const Permission(token: 'admin')), isTrue);
      expect(held.grants(const Permission(token: 'a')), isTrue);
    });
  });

  group('PermissionSetMatching extension', () {
    const required = Permission(token: 'finance.invoice.create');

    test('grant returns true when any held permission satisfies', () {
      final held = <Permission>{
        const Permission(token: 'inventory.read'),
        const Permission(token: 'finance.*'),
      };
      expect(held.grant(required), isTrue);
    });

    test('grant returns false when nothing matches', () {
      final held = <Permission>{
        const Permission(token: 'inventory.read'),
        const Permission(token: 'finance.report.export'),
      };
      expect(held.grant(required), isFalse);
    });

    test('empty held set never grants', () {
      expect(<Permission>{}.grant(required), isFalse);
    });
  });

  group('Permission — equality (freezed)', () {
    test('two Permissions with the same token are equal', () {
      expect(
        const Permission(token: 'finance.invoice.create'),
        const Permission(token: 'finance.invoice.create'),
      );
    });

    test('different tokens are unequal', () {
      expect(
        const Permission(token: 'a'),
        isNot(const Permission(token: 'b')),
      );
    });
  });
}
