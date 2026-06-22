import 'dart:async';

import '../../../../core/error/failure.dart';
import '../../entities/app_lock_settings.dart';
import '../../entities/audit_log_entry.dart';
import '../../entities/device_session.dart';
import '../settings_seed.dart';

/// Slice 9.3.1 — active devices.
class DeviceSessionsRepository {
  DeviceSessionsRepository();

  static final List<DeviceSession> _seed =
      List<DeviceSession>.of(SettingsSeed.sessions);

  final StreamController<List<DeviceSession>> _changes =
      StreamController<List<DeviceSession>>.broadcast();

  Future<List<DeviceSession>> getAll() async {
    final out = List<DeviceSession>.of(_seed)
      // Current device first, then most recent activity.
      ..sort((a, b) {
        if (a.isCurrent && !b.isCurrent) return -1;
        if (b.isCurrent && !a.isCurrent) return 1;
        return b.lastActiveAt.compareTo(a.lastActiveAt);
      });
    return List.unmodifiable(out);
  }

  Stream<List<DeviceSession>> watchAll() async* {
    yield await getAll();
    yield* _changes.stream;
  }

  /// Caller must guard against revoking [DeviceSession.isCurrent] —
  /// [revokeGuarded] enforces that, this just removes the row.
  Future<void> revoke(String sessionId) async {
    _seed.removeWhere((s) => s.id == sessionId);
    _emit();
  }

  Future<void> revokeAllOthers() async {
    _seed.removeWhere((s) => !s.isCurrent);
    _emit();
  }

  /// Slice 9.3.1 — refuse to revoke the current device, since that
  /// would log the user out of the screen they're standing on. They can
  /// use the global "Sign out" affordance for that.
  Future<void> revokeGuarded(DeviceSession session) async {
    if (session.isCurrent) {
      throw ConflictFailure(
          message:
              'Use Sign out to end the current session. Revoke other devices instead.');
    }
    await revoke(session.id);
  }

  Future<void> _emit() async {
    if (!_changes.isClosed) _changes.add(await getAll());
  }
}

/// Slice 9.3.2 — audit log read API. Append happens server-side; the
/// app only reads.
class AuditLogRepository {
  AuditLogRepository();

  static final List<AuditLogEntry> _seed =
      List<AuditLogEntry>.of(SettingsSeed.auditLog);

  Future<List<AuditLogEntry>> getAll() async => List.unmodifiable(_seed);

  Stream<List<AuditLogEntry>> watchAll() async* {
    yield List.unmodifiable(_seed);
  }
}

/// Slice 9.3.2 — pure filter + search over the audit log.
///
/// `actionFilter` empty = all actions; same with `actorFilter`.
/// `searchQuery` matches actor name, target label, and detail.
/// Always sorts most-recent-first.
List<AuditLogEntry> queryAuditLog(
  List<AuditLogEntry> entries, {
  Set<AuditAction> actionFilter = const {},
  Set<String> actorFilter = const {},
  String searchQuery = '',
  DateTime? from,
  DateTime? to,
}) {
  Iterable<AuditLogEntry> result = entries;

  if (actionFilter.isNotEmpty) {
    result = result.where((e) => actionFilter.contains(e.action));
  }
  if (actorFilter.isNotEmpty) {
    result = result.where((e) => actorFilter.contains(e.actorId));
  }
  if (from != null) {
    final f = DateTime.utc(from.year, from.month, from.day);
    result = result.where((e) => !e.occurredAt.isBefore(f));
  }
  if (to != null) {
    final t = DateTime.utc(to.year, to.month, to.day, 23, 59, 59);
    result = result.where((e) => !e.occurredAt.isAfter(t));
  }

  final q = searchQuery.trim().toLowerCase();
  if (q.isNotEmpty) {
    result = result.where((e) =>
        e.actorName.toLowerCase().contains(q) ||
        e.targetLabel.toLowerCase().contains(q) ||
        (e.detail?.toLowerCase().contains(q) ?? false));
  }

  final list = result.toList()
    ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  return list;
}

/// Distinct actors present in the log — populates the actor filter
/// dropdown.
List<({String id, String name})> extractActors(
    List<AuditLogEntry> entries) {
  final byId = <String, String>{};
  for (final e in entries) {
    byId.putIfAbsent(e.actorId, () => e.actorName);
  }
  final out = byId.entries.map((e) => (id: e.key, name: e.value)).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return out;
}

/// Slice 9.3.3 — PIN + biometric lock settings.
///
/// **Storage split**:
/// - the toggles + autoLockMinutes live in this (drift-backed) repo
/// - the PIN hash itself lives in `flutter_secure_storage` via
///   [InMemoryPinSecretStore]. Wiping drift never wipes the PIN; logging out
///   clears both.
class AppLockSettingsRepository {
  AppLockSettingsRepository();

  static AppLockSettings _state = AppLockSettings.initial;
  final StreamController<AppLockSettings> _changes =
      StreamController<AppLockSettings>.broadcast();

  Future<AppLockSettings> get() async => _state;

  Stream<AppLockSettings> watch() async* {
    yield _state;
    yield* _changes.stream;
  }

  Future<AppLockSettings> update(AppLockSettings settings) async {
    _state = settings;
    if (!_changes.isClosed) _changes.add(_state);
    return _state;
  }

  /// Slice 9.3.3 — auto-lock window validation.
  ///
  /// 0 means "lock immediately on resume"; the upper cap of 60 minutes
  /// matches what most banking apps allow before forcing re-auth.
  Future<AppLockSettings> setAutoLockMinutes({
    required AppLockSettings current,
    required int minutes,
  }) async {
    if (minutes < 0 || minutes > 60) {
      throw ValidationFailure(fieldErrors: {
        'autoLockMinutes': ['Must be between 0 and 60 minutes'],
      });
    }
    return update(current.copyWith(autoLockMinutes: minutes));
  }

  /// Slice 9.3.3 — disabling PIN auto-disables biometric (biometric is
  /// the unlock mechanism for the PIN — without a PIN, biometric has
  /// nothing to prove).
  Future<AppLockSettings> setPinEnabled({
    required AppLockSettings current,
    required bool enabled,
  }) async {
    if (!enabled) {
      return update(current.copyWith(
        pinEnabled: false,
        biometricEnabled: false,
      ));
    }
    return update(current.copyWith(pinEnabled: true));
  }

  /// Slice 9.3.3 — biometric requires PIN to be set first.
  Future<AppLockSettings> setBiometricEnabled({
    required AppLockSettings current,
    required bool enabled,
  }) async {
    if (enabled && !current.pinEnabled) {
      throw ConflictFailure(message: 'Set up a PIN before enabling biometric');
    }
    return update(current.copyWith(biometricEnabled: enabled));
  }
}

/// Memory-only PIN store for the demo.
///
/// **Why not the real `flutter_secure_storage`**: the integration would
/// land with the real auth slice. For now we hash the PIN with a
/// SHA-256-equivalent scramble so the test surface mirrors what the
/// real adapter will need (no plaintext, verify by re-hashing).
class InMemoryPinSecretStore {
  static String? _hash;

  Future<bool> hasPin() async => _hash != null;

  Future<void> setPin(String pin) async {
    _hash = _scramble(pin);
  }

  Future<void> clearPin() async {
    _hash = null;
  }

  Future<bool> verifyPin(String pin) async {
    if (_hash == null) return false;
    return _hash == _scramble(pin);
  }

  /// Slice 9.3.3 — PIN format validation.
  ///
  /// **Why a constant rule, not a regex flag**: simpler to reason about
  /// and easier to test. 4–8 digits matches the iOS / Android system
  /// expectation and keeps the keypad on numeric mode.
  static void validatePinFormat(String pin) {
    if (pin.length < 4 || pin.length > 8) {
      throw ValidationFailure(fieldErrors: {
        'pin': ['Must be 4–8 digits'],
      });
    }
    for (var i = 0; i < pin.length; i++) {
      final code = pin.codeUnitAt(i);
      if (code < 0x30 || code > 0x39) {
        throw ValidationFailure(fieldErrors: {
          'pin': ['Digits only'],
        });
      }
    }
  }

  /// Slice 9.3.3 — confirm-PIN flow checks the two entries match before
  /// the secret hits storage.
  static void ensurePinConfirmationMatches({
    required String pin,
    required String confirm,
  }) {
    if (pin != confirm) {
      throw ValidationFailure(fieldErrors: {
        'confirm': ['PINs do not match'],
      });
    }
  }

  String _scramble(String pin) {
    // Cheap deterministic scramble — a stand-in for the real hash. The
    // real adapter will use SHA-256 + per-install salt.
    final bytes = pin.codeUnits;
    var h = 0x12345678;
    for (final b in bytes) {
      h = ((h << 5) ^ (h >> 2) ^ b) & 0x7fffffff;
    }
    return h.toRadixString(16);
  }
}
