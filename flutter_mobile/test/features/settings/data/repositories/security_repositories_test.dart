import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/features/settings/data/repositories/security_repositories.dart';
import 'package:erp_mobile/features/settings/entities/app_lock_settings.dart';
import 'package:erp_mobile/features/settings/entities/audit_log_entry.dart';
import 'package:erp_mobile/features/settings/entities/device_session.dart';
import 'package:test/test.dart';

DeviceSession _s({String id = 's', bool isCurrent = false}) => DeviceSession(
      id: id,
      deviceLabel: 'Device',
      platform: 'Android 14',
      lastActiveAt: DateTime.utc(2026, 5, 15),
      signedInAt: DateTime.utc(2026, 5, 1),
      location: 'KH',
      isCurrent: isCurrent,
    );

AuditLogEntry _e({
  String id = 'a',
  String actorId = 'user-1',
  String actorName = 'Alice',
  AuditAction action = AuditAction.update,
  String targetLabel = 'Invoice',
  DateTime? at,
  String? detail,
}) =>
    AuditLogEntry(
      id: id,
      actorId: actorId,
      actorName: actorName,
      action: action,
      targetType: 'invoice',
      targetId: 't',
      targetLabel: targetLabel,
      occurredAt: at ?? DateTime.utc(2026, 5, 15),
      detail: detail,
    );

void main() {
  group('DeviceSessionsRepository.revokeGuarded', () {
    test('refuses to revoke the current device', () {
      final repo = DeviceSessionsRepository();
      expect(
        () => repo.revokeGuarded(_s(isCurrent: true)),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('passes for any other device', () async {
      final repo = DeviceSessionsRepository();
      await repo.revokeGuarded(_s(id: 'sess-other', isCurrent: false));
    });
  });

  group('AppLockSettingsRepository.setAutoLockMinutes', () {
    final base = AppLockSettings.initial;

    test('accepts 0 (immediate)', () async {
      final repo = AppLockSettingsRepository();
      final out = await repo.setAutoLockMinutes(current: base, minutes: 0);
      expect(out.autoLockMinutes, 0);
    });

    test('accepts 60 (max)', () async {
      final repo = AppLockSettingsRepository();
      final out = await repo.setAutoLockMinutes(current: base, minutes: 60);
      expect(out.autoLockMinutes, 60);
    });

    test('rejects negative', () {
      final repo = AppLockSettingsRepository();
      expect(
        () => repo.setAutoLockMinutes(current: base, minutes: -1),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('rejects >60', () {
      final repo = AppLockSettingsRepository();
      expect(
        () => repo.setAutoLockMinutes(current: base, minutes: 61),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('AppLockSettingsRepository.setPinEnabled', () {
    test('disabling PIN also disables biometric', () async {
      final repo = AppLockSettingsRepository();
      const enabled = AppLockSettings(
        pinEnabled: true,
        biometricEnabled: true,
        autoLockMinutes: 5,
      );
      final out = await repo.setPinEnabled(current: enabled, enabled: false);
      expect(out.pinEnabled, isFalse);
      expect(out.biometricEnabled, isFalse);
    });

    test('enabling PIN preserves biometric setting', () async {
      final repo = AppLockSettingsRepository();
      const noLock = AppLockSettings(
        pinEnabled: false,
        biometricEnabled: false,
        autoLockMinutes: 5,
      );
      final out = await repo.setPinEnabled(current: noLock, enabled: true);
      expect(out.pinEnabled, isTrue);
      expect(out.biometricEnabled, isFalse);
    });
  });

  group('AppLockSettingsRepository.setBiometricEnabled', () {
    test('refuses to enable biometric without PIN', () {
      final repo = AppLockSettingsRepository();
      expect(
        () => repo.setBiometricEnabled(
          current: AppLockSettings.initial,
          enabled: true,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('enables when PIN is set', () async {
      final repo = AppLockSettingsRepository();
      const withPin = AppLockSettings(
        pinEnabled: true,
        biometricEnabled: false,
        autoLockMinutes: 5,
      );
      final out = await repo.setBiometricEnabled(
        current: withPin,
        enabled: true,
      );
      expect(out.biometricEnabled, isTrue);
    });

    test('always allows disabling', () async {
      final repo = AppLockSettingsRepository();
      const withBoth = AppLockSettings(
        pinEnabled: true,
        biometricEnabled: true,
        autoLockMinutes: 5,
      );
      final out = await repo.setBiometricEnabled(
        current: withBoth,
        enabled: false,
      );
      expect(out.biometricEnabled, isFalse);
    });
  });

  group('InMemoryPinSecretStore.validatePinFormat', () {
    test('accepts 4–8 digits', () {
      InMemoryPinSecretStore.validatePinFormat('1234');
      InMemoryPinSecretStore.validatePinFormat('12345678');
    });

    test('rejects too short', () {
      expect(() => InMemoryPinSecretStore.validatePinFormat('123'),
          throwsA(isA<ValidationFailure>()));
    });

    test('rejects too long', () {
      expect(() => InMemoryPinSecretStore.validatePinFormat('123456789'),
          throwsA(isA<ValidationFailure>()));
    });

    test('rejects non-digits', () {
      expect(() => InMemoryPinSecretStore.validatePinFormat('12ab'),
          throwsA(isA<ValidationFailure>()));
    });
  });

  group('InMemoryPinSecretStore.ensurePinConfirmationMatches', () {
    test('passes when pins match', () {
      InMemoryPinSecretStore.ensurePinConfirmationMatches(
        pin: '1234',
        confirm: '1234',
      );
    });

    test('throws when pins differ', () {
      expect(
        () => InMemoryPinSecretStore.ensurePinConfirmationMatches(
          pin: '1234',
          confirm: '5678',
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('queryAuditLog', () {
    final all = [
      _e(id: '1', actorId: 'u1', actorName: 'Alice',
          action: AuditAction.approve,
          at: DateTime.utc(2026, 5, 14, 10, 0)),
      _e(id: '2', actorId: 'u2', actorName: 'Bob',
          action: AuditAction.reject,
          at: DateTime.utc(2026, 5, 15, 11, 0),
          detail: 'budget overrun'),
      _e(id: '3', actorId: 'u1', actorName: 'Alice',
          action: AuditAction.signIn,
          targetLabel: 'Pixel 7',
          at: DateTime.utc(2026, 5, 13, 9, 0)),
    ];

    test('default sort is most recent first', () {
      final out = queryAuditLog(all);
      expect(out.map((e) => e.id).toList(), ['2', '1', '3']);
    });

    test('action filter narrows results', () {
      final out = queryAuditLog(all, actionFilter: {AuditAction.approve});
      expect(out, hasLength(1));
      expect(out.single.id, '1');
    });

    test('actor filter narrows results', () {
      final out = queryAuditLog(all, actorFilter: {'u1'});
      expect(out.map((e) => e.id).toSet(), {'1', '3'});
    });

    test('search hits actor, target, and detail', () {
      // Detail match.
      expect(queryAuditLog(all, searchQuery: 'budget').single.id, '2');
      // Target label match.
      expect(queryAuditLog(all, searchQuery: 'pixel').single.id, '3');
    });

    test('date filter inclusive on both ends', () {
      final out = queryAuditLog(
        all,
        from: DateTime.utc(2026, 5, 14),
        to: DateTime.utc(2026, 5, 14),
      );
      expect(out.single.id, '1');
    });

    test('empty input → empty output', () {
      expect(queryAuditLog(const []), isEmpty);
    });
  });

  group('extractActors', () {
    test('returns distinct actors sorted by name', () {
      final out = extractActors([
        _e(actorId: 'u-z', actorName: 'Zach'),
        _e(actorId: 'u-a', actorName: 'Alice'),
        _e(actorId: 'u-z', actorName: 'Zach'),
      ]);
      expect(out.map((a) => a.id).toList(), ['u-a', 'u-z']);
    });
  });
}
