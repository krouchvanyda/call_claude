import 'package:erp_mobile/core/shortcuts/permission_filter.dart';
import 'package:erp_mobile/features/auth/entities/permission.dart';
import 'package:test/test.dart';

/// Test fixture — a generic stand-in for `ModuleShortcut` so the filter
/// tests stay Flutter-free (the real shortcut class drags in IconData).
class _Item {
  const _Item(this.id, this.requiredPermission);
  final String id;
  final Permission? requiredPermission;
}

const _items = <_Item>[
  _Item('public', null),
  _Item('admin', Permission(token: 'admin')),
  _Item('finance-any', Permission(token: 'finance.*')),
  _Item('finance-read', Permission(token: 'finance.invoice.read')),
  _Item('inventory-read', Permission(token: 'inventory.stock.read')),
];

void main() {
  group('filterByPermission', () {
    test('keeps items with no required permission (always visible)', () {
      final result = filterByPermission<_Item>(
        _items,
        (i) => i.requiredPermission,
        const <Permission>{},
      ).map((i) => i.id).toList();

      expect(result, ['public']);
    });

    test('exact-match grants the corresponding gated item', () {
      final result = filterByPermission<_Item>(
        _items,
        (i) => i.requiredPermission,
        {const Permission(token: 'finance.invoice.read')},
      ).map((i) => i.id).toSet();

      expect(result, {'public', 'finance-read'});
    });

    test('held wildcard grants every gated item it covers', () {
      final result = filterByPermission<_Item>(
        _items,
        (i) => i.requiredPermission,
        {const Permission(token: 'finance.*')},
      ).map((i) => i.id).toSet();

      expect(
        result,
        {'public', 'finance-any', 'finance-read'},
        reason:
            'finance.* should grant the literal finance.* tile AND the '
            'finance.invoice.read tile via wildcard cover',
      );
    });

    test('admin (bare token) grants only the admin-gated tile', () {
      final result = filterByPermission<_Item>(
        _items,
        (i) => i.requiredPermission,
        {const Permission(token: 'admin')},
      ).map((i) => i.id).toSet();

      expect(result, {'public', 'admin'});
    });

    test('multiple held permissions union their visibility', () {
      final result = filterByPermission<_Item>(
        _items,
        (i) => i.requiredPermission,
        {
          const Permission(token: 'admin'),
          const Permission(token: 'inventory.*'),
        },
      ).map((i) => i.id).toSet();

      expect(result, {'public', 'admin', 'inventory-read'});
    });

    test('preserves source order (catalog order is on-screen order)', () {
      final result = filterByPermission<_Item>(
        _items,
        (i) => i.requiredPermission,
        {
          const Permission(token: 'admin'),
          const Permission(token: 'finance.*'),
        },
      ).map((i) => i.id).toList();

      // _items declares: public, admin, finance-any, finance-read, ...
      expect(result, ['public', 'admin', 'finance-any', 'finance-read']);
    });

    test('empty input → empty output', () {
      final result = filterByPermission<_Item>(
        const <_Item>[],
        (i) => i.requiredPermission,
        {const Permission(token: 'admin')},
      );
      expect(result, isEmpty);
    });
  });
}
