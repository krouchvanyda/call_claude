import 'dart:async';

import 'package:erp_mobile/features/auth/entities/permission.dart';
import 'package:erp_mobile/features/search/domain/entities/search_result.dart';
import 'package:erp_mobile/features/search/domain/repositories/search_provider.dart';
import 'package:erp_mobile/features/search/domain/usecases/federated_search.dart';
import 'package:test/test.dart';

class _StaticProvider implements SearchProvider {
  _StaticProvider({
    required this.id,
    required List<SearchResult> results,
    Permission? requiredPermission,
    bool throws = false,
    Duration? delay,
  })  : _results = results,
        _requiredPermission = requiredPermission,
        _throws = throws,
        _delay = delay;

  @override
  final String id;
  final List<SearchResult> _results;
  final Permission? _requiredPermission;
  final bool _throws;
  final Duration? _delay;

  int callCount = 0;

  @override
  Permission? get requiredPermission => _requiredPermission;

  @override
  Future<List<SearchResult>> search(String query) async {
    callCount++;
    if (_delay != null) await Future.delayed(_delay);
    if (_throws) throw StateError('boom from $id');
    return _results;
  }
}

SearchResult _r(String providerId, String id) => SearchResult(
      id: id,
      title: id,
      providerId: providerId,
    );

void main() {
  group('FederatedSearchUseCase', () {
    test('empty / whitespace query short-circuits to empty list (no provider hit)',
        () async {
      final p = _StaticProvider(id: 'a', results: [_r('a', '1')]);
      final useCase = FederatedSearchUseCase(
        providers: [p],
        holds: (_) => true,
      );

      expect(await useCase.call(''), isEmpty);
      expect(await useCase.call('   '), isEmpty);
      expect(p.callCount, 0,
          reason: 'short-circuit must avoid hitting providers');
    });

    test('fans out to every eligible provider in parallel and aggregates',
        () async {
      final a = _StaticProvider(id: 'a', results: [_r('a', '1'), _r('a', '2')]);
      final b = _StaticProvider(id: 'b', results: [_r('b', '9')]);

      final groups = await FederatedSearchUseCase(
        providers: [a, b],
        holds: (_) => true,
      ).call('hello');

      expect(groups, hasLength(2));
      expect(groups[0].providerId, 'a');
      expect(groups[0].results.map((r) => r.id), ['1', '2']);
      expect(groups[1].providerId, 'b');
      expect(groups[1].results.map((r) => r.id), ['9']);
    });

    test('drops empty groups so the UI does not render bare headers',
        () async {
      final hits = _StaticProvider(id: 'a', results: [_r('a', '1')]);
      final empty = _StaticProvider(id: 'b', results: const []);

      final groups = await FederatedSearchUseCase(
        providers: [hits, empty],
        holds: (_) => true,
      ).call('q');

      expect(groups.map((g) => g.providerId), ['a']);
    });

    group('permission gate', () {
      test('skips providers whose requiredPermission is unmet (no search() call)',
          () async {
        final gated = _StaticProvider(
          id: 'finance',
          results: [_r('finance', '1')],
          requiredPermission: const Permission(token: 'finance.*'),
        );
        final ungated =
            _StaticProvider(id: 'modules', results: [_r('modules', '2')]);

        final groups = await FederatedSearchUseCase(
          providers: [gated, ungated],
          holds: (_) => false, // user holds nothing
        ).call('q');

        expect(gated.callCount, 0,
            reason: 'gated provider must not be invoked when held=false');
        expect(ungated.callCount, 1);
        expect(groups.map((g) => g.providerId), ['modules']);
      });

      test('honours wildcard semantics via the held() callback', () async {
        // Wildcard semantics are HELD-side: a user with the broad
        // `finance.*` token satisfies a provider that requires the
        // narrower `finance.invoice.read`. (The reverse is NOT true —
        // a literal token never satisfies a wildcard requirement.)
        final gated = _StaticProvider(
          id: 'finance',
          results: [_r('finance', '1')],
          requiredPermission: const Permission(token: 'finance.invoice.read'),
        );
        final held = {const Permission(token: 'finance.*')};

        // Mirror what PermissionsSnapshot.holds does: delegate to grant().
        final groups = await FederatedSearchUseCase(
          providers: [gated],
          holds: (req) => held.grant(req),
        ).call('q');

        expect(groups, hasLength(1));
      });
    });

    group('failure isolation', () {
      test('one provider throwing yields an empty group for it but others survive',
          () async {
        final boom =
            _StaticProvider(id: 'boom', results: const [], throws: true);
        final ok = _StaticProvider(id: 'ok', results: [_r('ok', '1')]);

        final groups = await FederatedSearchUseCase(
          providers: [boom, ok],
          holds: (_) => true,
        ).call('q');

        // boom's empty group is filtered out; ok's group survives.
        expect(groups.map((g) => g.providerId), ['ok']);
      });

      test('every provider throwing yields an empty result list (not a thrown error)',
          () async {
        final a = _StaticProvider(id: 'a', results: const [], throws: true);
        final b = _StaticProvider(id: 'b', results: const [], throws: true);

        final groups = await FederatedSearchUseCase(
          providers: [a, b],
          holds: (_) => true,
        ).call('q');

        expect(groups, isEmpty);
      });
    });

    test(
        'parallel fan-out: total time ≈ slowest provider, not sum of all '
        '(verifies Future.wait, not sequential await)',
        () async {
      final slow = _StaticProvider(
        id: 'slow',
        results: [_r('slow', '1')],
        delay: const Duration(milliseconds: 80),
      );
      final alsoSlow = _StaticProvider(
        id: 'alsoSlow',
        results: [_r('alsoSlow', '1')],
        delay: const Duration(milliseconds: 80),
      );

      final stopwatch = Stopwatch()..start();
      await FederatedSearchUseCase(
        providers: [slow, alsoSlow],
        holds: (_) => true,
      ).call('q');
      stopwatch.stop();

      // Sequential would be ≈160ms; parallel should be ≈80ms. Allow
      // generous slack for CI jitter — the "not sequential" intent is
      // what we're locking, not millisecond precision.
      expect(stopwatch.elapsed,
          lessThan(const Duration(milliseconds: 140)),
          reason: 'providers must run in parallel via Future.wait');
    });
  });
}
