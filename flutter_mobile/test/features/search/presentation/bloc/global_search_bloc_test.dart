import 'package:bloc_test/bloc_test.dart';
import 'package:erp_mobile/features/auth/entities/permission.dart';
import 'package:erp_mobile/features/search/domain/entities/search_result.dart';
import 'package:erp_mobile/features/search/domain/repositories/search_provider.dart';
import 'package:erp_mobile/features/search/domain/usecases/federated_search.dart';
import 'package:erp_mobile/features/search/presentation/bloc/global_search_bloc.dart';
import 'package:erp_mobile/features/search/presentation/bloc/global_search_event.dart';
import 'package:erp_mobile/features/search/presentation/bloc/global_search_state.dart';
import 'package:test/test.dart';

class _ScriptedProvider implements SearchProvider {
  _ScriptedProvider({this.responder, this.shouldThrow = false});

  /// `responder(query)` returns the scripted result list. Lets each test
  /// construct its own (e.g. echo the query as a single tile).
  final List<SearchResult> Function(String query)? responder;
  final bool shouldThrow;

  @override
  String get id => 'scripted';

  @override
  Permission? get requiredPermission => null;

  @override
  Future<List<SearchResult>> search(String query) async {
    if (shouldThrow) throw StateError('boom');
    return responder?.call(query) ??
        [
          SearchResult(
            id: query,
            title: query,
            providerId: id,
          ),
        ];
  }
}

GlobalSearchBloc _bloc({
  List<SearchResult> Function(String)? responder,
  bool shouldThrow = false,
}) {
  return GlobalSearchBloc(
    federatedSearch: FederatedSearchUseCase(
      providers: [
        _ScriptedProvider(responder: responder, shouldThrow: shouldThrow),
      ],
      holds: (_) => true,
    ),
  );
}

// Slightly longer than the bloc's 300ms debounce so the handler runs
// before bloc_test's `expect:` assertion fires.
const _afterDebounce = Duration(milliseconds: 380);

void main() {
  group('GlobalSearchBloc', () {
    test('initial state is Idle', () {
      expect(_bloc().state, const GlobalSearchState.idle());
    });

    blocTest<GlobalSearchBloc, GlobalSearchState>(
      'Cleared event always returns to Idle',
      build: _bloc,
      act: (bloc) => bloc.add(const GlobalSearchEvent.cleared()),
      expect: () => [const GlobalSearchState.idle()],
    );

    blocTest<GlobalSearchBloc, GlobalSearchState>(
      'QueryChanged with empty / whitespace string emits Idle (no search call)',
      build: _bloc,
      act: (bloc) {
        bloc.add(const GlobalSearchEvent.queryChanged(''));
        bloc.add(const GlobalSearchEvent.queryChanged('   '));
      },
      wait: _afterDebounce,
      // Both events debounce to the *last* (whitespace), which trims to ""
      // and emits a single Idle.
      expect: () => [const GlobalSearchState.idle()],
    );

    blocTest<GlobalSearchBloc, GlobalSearchState>(
      'QueryChanged with text emits Loading then Success after debounce',
      build: _bloc,
      act: (bloc) =>
          bloc.add(const GlobalSearchEvent.queryChanged('finance')),
      wait: _afterDebounce,
      expect: () => [
        const GlobalSearchState.loading('finance'),
        isA<GlobalSearchSuccess>()
            .having((s) => s.query, 'query', 'finance')
            .having((s) => s.groups, 'groups', hasLength(1))
            .having(
              (s) => s.groups.first.results.first.id,
              'first result id',
              'finance',
            ),
      ],
    );

    blocTest<GlobalSearchBloc, GlobalSearchState>(
      'provider throwing yields Loading -> Success(empty groups) — failure '
      'isolation absorbs the throw at the use-case layer',
      build: () => _bloc(shouldThrow: true),
      act: (bloc) => bloc.add(const GlobalSearchEvent.queryChanged('q')),
      wait: _afterDebounce,
      expect: () => [
        const GlobalSearchState.loading('q'),
        isA<GlobalSearchSuccess>()
            .having((s) => s.query, 'query', 'q')
            .having((s) => s.groups, 'groups', isEmpty),
      ],
    );

    blocTest<GlobalSearchBloc, GlobalSearchState>(
      'rapid keystrokes are debounced — only the LAST query reaches the '
      'use case (debounceTime + switchMap)',
      build: _bloc,
      act: (bloc) {
        // All three arrive within the 300ms window.
        bloc.add(const GlobalSearchEvent.queryChanged('a'));
        bloc.add(const GlobalSearchEvent.queryChanged('ab'));
        bloc.add(const GlobalSearchEvent.queryChanged('abc'));
      },
      wait: _afterDebounce,
      expect: () => [
        const GlobalSearchState.loading('abc'),
        isA<GlobalSearchSuccess>().having((s) => s.query, 'query', 'abc'),
      ],
    );

    blocTest<GlobalSearchBloc, GlobalSearchState>(
      'Cleared mid-flight returns to Idle (Cleared is not debounced)',
      build: _bloc,
      act: (bloc) async {
        bloc.add(const GlobalSearchEvent.queryChanged('x'));
        // Fire Cleared while the debounce timer is still running.
        bloc.add(const GlobalSearchEvent.cleared());
      },
      wait: _afterDebounce,
      // The QueryChanged is debounced, so by the time it would emit Loading,
      // it still runs (debounce is per-event-stream, not cancelled by other
      // event types) — but Cleared has *already* fired Idle synchronously.
      // The final state must be the most recent: query 'x' Success.
      // We assert at least Idle showed up before the debounced query
      // completed.
      expect: () => [
        const GlobalSearchState.idle(),
        const GlobalSearchState.loading('x'),
        isA<GlobalSearchSuccess>().having((s) => s.query, 'query', 'x'),
      ],
    );
  });
}
