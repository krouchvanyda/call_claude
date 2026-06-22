import '../../entities/contact.dart';
import '../sales_seed.dart';

/// Slice 6.1.2 — customer contacts.
class ContactsRepository {
  ContactsRepository();

  static final List<CustomerContact> _seed =
      List<CustomerContact>.of(SalesSeed.contacts);
  static int _idCounter = 100;

  Future<List<CustomerContact>> forCustomer(String customerId) async {
    final list = _seed.where((c) => c.customerId == customerId).toList();
    // Primary first; then alphabetical by name.
    list.sort((a, b) {
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return List.unmodifiable(list);
  }

  /// Persists a new contact (Slice 6.1.2). Returns the persisted row
  /// (the repo assigns the id).
  Future<CustomerContact> create(CustomerContact draft) async {
    _idCounter++;
    // Enforce single-primary invariant per customer.
    if (draft.isPrimary) {
      for (var i = 0; i < _seed.length; i++) {
        if (_seed[i].customerId == draft.customerId && _seed[i].isPrimary) {
          _seed[i] = _seed[i].copyWith(isPrimary: false);
        }
      }
    }
    final persisted = draft.copyWith(id: 'ct-${_idCounter.toString().padLeft(3, '0')}');
    _seed.add(persisted);
    return persisted;
  }

  /// Replaces an existing contact in place. Throws [StateError] when
  /// the id is unknown.
  Future<CustomerContact> update(CustomerContact updated) async {
    final idx = _seed.indexWhere((c) => c.id == updated.id);
    if (idx == -1) throw StateError('Contact "${updated.id}" not found');
    if (updated.isPrimary) {
      for (var i = 0; i < _seed.length; i++) {
        if (i == idx) continue;
        if (_seed[i].customerId == updated.customerId &&
            _seed[i].isPrimary) {
          _seed[i] = _seed[i].copyWith(isPrimary: false);
        }
      }
    }
    _seed[idx] = updated;
    return updated;
  }

  Future<void> delete(String contactId) async {
    _seed.removeWhere((c) => c.id == contactId);
  }
}
