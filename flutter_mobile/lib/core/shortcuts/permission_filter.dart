import '../../features/auth/entities/permission.dart';

/// Pure-Dart generic permission filter.
///
/// Kept generic (not specialised to `ModuleShortcut`) so it stays free of
/// Flutter imports — and so the same predicate can be re-used by other
/// permission-gated lists (action menus, drawer items, future settings
/// sections) without a copy.
///
/// `requiredOf(item)` returns the permission an item demands, or `null`
/// when the item is ungated (always visible to any signed-in user).
/// Wildcards in the held set are honoured via [Permission.grants].
Iterable<T> filterByPermission<T>(
  Iterable<T> items,
  Permission? Function(T item) requiredOf,
  Set<Permission> held,
) {
  return items.where((item) {
    final required = requiredOf(item);
    return required == null || held.grant(required);
  });
}
