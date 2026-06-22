import 'dart:async';

import '../../entities/customer.dart';
import '../sales_seed.dart';

/// Slice 6.1.1 — master customer directory.
class CustomersRepository {
  CustomersRepository();

  static final List<Customer> _seed = List<Customer>.of(SalesSeed.customers);
  static int _idCounter = 100;

  final StreamController<List<Customer>> _changes =
      StreamController<List<Customer>>.broadcast();

  Future<List<Customer>> getAll() async => List.unmodifiable(_seed);

  Stream<List<Customer>> watchAll() async* {
    yield List.unmodifiable(_seed);
    yield* _changes.stream;
  }

  Future<Customer?> findById(String id) async {
    for (final c in _seed) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<Customer> create(Customer draft) async {
    _idCounter++;
    final persisted = draft.copyWith(
      id: 'cust-${_idCounter.toString().padLeft(3, '0')}',
      onboardedAt: draft.onboardedAt,
      lifetimeValue: draft.lifetimeValue.isEmpty ? '฿0.00' : draft.lifetimeValue,
    );
    _seed.add(persisted);
    _changes.add(List.unmodifiable(_seed));
    return persisted;
  }

  Future<Customer> update(Customer updated) async {
    final idx = _seed.indexWhere((c) => c.id == updated.id);
    if (idx == -1) throw StateError('Customer "${updated.id}" not found');
    _seed[idx] = updated;
    _changes.add(List.unmodifiable(_seed));
    return updated;
  }
}

/// Pure filter + sort over the customer list (Slice 6.1.1).
List<Customer> applyCustomerQuery(
  List<Customer> all, {
  Set<CustomerStatus> statusFilter = const {},
  Set<CustomerSegment> segmentFilter = const {},
  String searchQuery = '',
  CustomerSort sort = CustomerSort.nameAsc,
}) {
  Iterable<Customer> result = all;

  if (statusFilter.isNotEmpty) {
    result = result.where((c) => statusFilter.contains(c.status));
  }
  if (segmentFilter.isNotEmpty) {
    result = result.where((c) => segmentFilter.contains(c.segment));
  }

  final q = searchQuery.trim().toLowerCase();
  if (q.isNotEmpty) {
    result = result.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.email.toLowerCase().contains(q) ||
        (c.industry?.toLowerCase().contains(q) ?? false));
  }

  final list = result.toList();
  switch (sort) {
    case CustomerSort.nameAsc:
      list.sort((a, b) => a.name.compareTo(b.name));
    case CustomerSort.lifetimeValueDesc:
      // Pre-formatted strings — strip non-digits before comparing so
      // `r'$8,400.00'` sorts above `r'$640.00'` correctly.
      num parse(String v) {
        final cleaned = v.replaceAll(RegExp(r'[^0-9.\-]'), '');
        return num.tryParse(cleaned) ?? 0;
      }

      list.sort(
          (a, b) => parse(b.lifetimeValue).compareTo(parse(a.lifetimeValue)));
    case CustomerSort.recentlyAdded:
      list.sort((a, b) => b.onboardedAt.compareTo(a.onboardedAt));
  }
  return list;
}
