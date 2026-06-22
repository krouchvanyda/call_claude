import 'package:erp_mobile/core/sync/conflict.dart';
import 'package:erp_mobile/core/sync/conflict_policy.dart';
import 'package:erp_mobile/core/sync/conflict_policy_registry.dart';
import 'package:test/test.dart';

// ── A small test fixture so we don't lean on real domain types ──────
typedef Doc = ({String body, int version});

const _localDoc = (body: 'local edit', version: 7);
const _serverDoc = (body: 'server edit', version: 7);

DateTime _t(int hour) => DateTime.utc(2026, 5, 12, hour);

void main() {
  group('ServerWinsPolicy', () {
    const policy = ServerWinsPolicy();

    test('always returns the server value', () {
      const conflict = Conflict(local: _localDoc, server: _serverDoc);
      expect(policy.resolve(conflict), _serverDoc);
    });

    test('ignores timestamps entirely', () {
      final conflict = Conflict(
        local: _localDoc,
        server: _serverDoc,
        localUpdatedAt: _t(15), // local is newer
        serverUpdatedAt: _t(9),
      );
      expect(policy.resolve(conflict), _serverDoc);
    });

    test('works for any type via the method-generic interface', () {
      const stringConflict = Conflict(local: 'l', server: 's');
      const intConflict = Conflict(local: 1, server: 2);
      expect(policy.resolve(stringConflict), 's');
      expect(policy.resolve(intConflict), 2);
    });
  });

  group('ClientWinsPolicy', () {
    const policy = ClientWinsPolicy();

    test('always returns the local value', () {
      const conflict = Conflict(local: _localDoc, server: _serverDoc);
      expect(policy.resolve(conflict), _localDoc);
    });

    test('ignores timestamps', () {
      final conflict = Conflict(
        local: _localDoc,
        server: _serverDoc,
        localUpdatedAt: _t(9), // server is newer
        serverUpdatedAt: _t(15),
      );
      expect(policy.resolve(conflict), _localDoc);
    });
  });

  group('LastWriteWinsPolicy', () {
    const policy = LastWriteWinsPolicy();

    test('returns the side with the later timestamp — local', () {
      final conflict = Conflict(
        local: _localDoc,
        server: _serverDoc,
        localUpdatedAt: _t(15),
        serverUpdatedAt: _t(9),
      );
      expect(policy.resolve(conflict), _localDoc);
    });

    test('returns the side with the later timestamp — server', () {
      final conflict = Conflict(
        local: _localDoc,
        server: _serverDoc,
        localUpdatedAt: _t(9),
        serverUpdatedAt: _t(15),
      );
      expect(policy.resolve(conflict), _serverDoc);
    });

    test('falls back to the default tiebreaker (server) when equal', () {
      final conflict = Conflict(
        local: _localDoc,
        server: _serverDoc,
        localUpdatedAt: _t(12),
        serverUpdatedAt: _t(12),
      );
      expect(policy.resolve(conflict), _serverDoc);
    });

    test('falls back when localUpdatedAt is missing', () {
      final conflict = Conflict(
        local: _localDoc,
        server: _serverDoc,
        serverUpdatedAt: _t(15),
      );
      expect(policy.resolve(conflict), _serverDoc);
    });

    test('falls back when serverUpdatedAt is missing', () {
      final conflict = Conflict(
        local: _localDoc,
        server: _serverDoc,
        localUpdatedAt: _t(15),
      );
      expect(policy.resolve(conflict), _serverDoc);
    });

    test('respects a custom tiebreaker — ClientWins', () {
      const policy = LastWriteWinsPolicy(tiebreaker: ClientWinsPolicy());
      const conflict = Conflict(local: _localDoc, server: _serverDoc);
      expect(policy.resolve(conflict), _localDoc);
    });
  });

  group('ConflictPolicyRegistry', () {
    test('returns the default policy when no override is registered', () {
      final registry = ConflictPolicyRegistry();
      expect(registry.policyFor('invoice'), isA<ServerWinsPolicy>());
    });

    test('honours per-entity overrides', () {
      final registry = ConflictPolicyRegistry(
        overrides: const {
          'note': ClientWinsPolicy(),
          'audit_log': LastWriteWinsPolicy(),
        },
      );

      expect(registry.policyFor('note'), isA<ClientWinsPolicy>());
      expect(registry.policyFor('audit_log'), isA<LastWriteWinsPolicy>());
      expect(registry.policyFor('invoice'), isA<ServerWinsPolicy>(),
          reason: 'unregistered entity falls back to the default policy');
    });

    test('respects a non-default fallback', () {
      final registry = ConflictPolicyRegistry(
        defaultPolicy: const ClientWinsPolicy(),
      );
      expect(registry.policyFor('anything'), isA<ClientWinsPolicy>());
    });

    test('overrides map is immutable from outside', () {
      final mutable = <String, ConflictPolicy>{
        'note': const ClientWinsPolicy(),
      };
      final registry = ConflictPolicyRegistry(overrides: mutable);

      // Mutating the input after construction must not affect the registry.
      mutable['invoice'] = const ClientWinsPolicy();
      expect(registry.policyFor('invoice'), isA<ServerWinsPolicy>());

      // Reading the exposed map and trying to mutate it must throw.
      expect(
        () => registry.overrides['x'] = const ClientWinsPolicy(),
        throwsUnsupportedError,
      );
    });
  });
}
