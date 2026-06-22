import 'package:erp_mobile/features/auth/data/datasources/secret_store.dart';

/// In-memory [SecretStore] for tests. Behaves like the production
/// `flutter_secure_storage` adapter but keeps everything in a Dart `Map`
/// so the test suite never touches the platform plugin (which would drag
/// Flutter into pure-Dart tests).
///
/// Append-only diagnostic surface (`writes`, `deletes`) is exposed so
/// integration tests can assert *which* keys were touched, not just the
/// final state.
class InMemorySecretStore implements SecretStore {
  final Map<String, String> _store = {};
  final List<String> writes = [];
  final List<String> deletes = [];

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
    writes.add(key);
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
    deletes.add(key);
  }

  @override
  Future<void> deleteAll() async {
    deletes.addAll(_store.keys);
    _store.clear();
  }

  /// Test introspection — peek at what was actually persisted under a key.
  String? peek(String key) => _store[key];

  /// Force-corrupt the value at [key] — used to verify defensive reads.
  void corrupt(String key, String garbage) => _store[key] = garbage;

  int get keyCount => _store.length;
}
