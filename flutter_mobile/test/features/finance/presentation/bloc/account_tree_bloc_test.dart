import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:erp_mobile/core/utils/logger/app_logger.dart';
import 'package:erp_mobile/core/utils/logger/log_level.dart';
import 'package:erp_mobile/features/finance/data/repositories/accounts_repository.dart';
import 'package:erp_mobile/features/finance/entities/account.dart';
import 'package:erp_mobile/features/finance/presentation/bloc/account_tree_bloc.dart';
import 'package:erp_mobile/features/finance/presentation/bloc/account_tree_event.dart';
import 'package:erp_mobile/features/finance/presentation/bloc/account_tree_state.dart';
import 'package:test/test.dart';

class _NoopLogger extends AppLogger {
  @override
  void log(LogLevel level, String message,
      {Object? error,
      StackTrace? stackTrace,
      Map<String, Object?>? context}) {}
}

class _FakeRepo implements AccountsRepository {
  final _ctrl = StreamController<List<Account>>.broadcast();

  void emit(List<Account> snapshot) => _ctrl.add(snapshot);
  void emitError(Object e) => _ctrl.addError(e);

  @override
  Stream<List<Account>> watchAll() => _ctrl.stream;

  @override
  Future<List<Account>> getAll() async => const [];

  @override
  Future<Account?> findById(String id) async => null;

  Future<void> close() => _ctrl.close();
}

Account _a(String id, {String? parent, String? code}) => Account(
      id: id,
      code: code ?? id,
      name: id,
      type: AccountType.asset,
      parentId: parent,
    );

void main() {
  late _FakeRepo repo;

  setUp(() => repo = _FakeRepo());
  tearDown(() => repo.close());

  group('AccountTreeBloc', () {
    test('initial state is Initial (no subscription before Started)', () {
      final bloc = AccountTreeBloc(repository: repo, logger: _NoopLogger());
      expect(bloc.state, const AccountTreeState.initial());
    });

    blocTest<AccountTreeBloc, AccountTreeState>(
      'Started → Loading then Loaded; default expansion opens roots only',
      build: () => AccountTreeBloc(repository: repo, logger: _NoopLogger()),
      act: (bloc) async {
        bloc.add(const AccountTreeEvent.started());
        await Future<void>.delayed(Duration.zero);
        repo.emit([
          _a('root-1', code: '1000'),
          _a('child', code: '1100', parent: 'root-1'),
          _a('root-2', code: '2000'),
        ]);
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const AccountTreeState.loading(),
        isA<AccountTreeLoaded>()
            .having((s) => s.roots.length, 'roots', 2)
            // Only the non-leaf root opens by default; the leaf root
            // and the deeper child stay collapsed.
            .having((s) => s.expandedIds, 'expanded', {'root-1'}),
      ],
    );

    blocTest<AccountTreeBloc, AccountTreeState>(
      'NodeToggled flips a single id (open then close)',
      build: () => AccountTreeBloc(repository: repo, logger: _NoopLogger()),
      act: (bloc) async {
        bloc.add(const AccountTreeEvent.started());
        await Future<void>.delayed(Duration.zero);
        repo.emit([
          _a('root', code: '1000'),
          _a('child', code: '1100', parent: 'root'),
          _a('grand', code: '1110', parent: 'child'),
        ]);
        await Future<void>.delayed(Duration.zero);
        // Toggle the child open.
        bloc.add(const AccountTreeEvent.nodeToggled('child'));
        await Future<void>.delayed(Duration.zero);
        // Toggle the root closed.
        bloc.add(const AccountTreeEvent.nodeToggled('root'));
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const AccountTreeState.loading(),
        // Loaded with default expansion: just root.
        isA<AccountTreeLoaded>().having((s) => s.expandedIds, 'expanded', {'root'}),
        // After child toggled open.
        isA<AccountTreeLoaded>()
            .having((s) => s.expandedIds, 'expanded', {'root', 'child'}),
        // After root toggled closed.
        isA<AccountTreeLoaded>()
            .having((s) => s.expandedIds, 'expanded', {'child'}),
      ],
    );

    blocTest<AccountTreeBloc, AccountTreeState>(
      'ExpandedAll opens every non-leaf node',
      build: () => AccountTreeBloc(repository: repo, logger: _NoopLogger()),
      act: (bloc) async {
        bloc.add(const AccountTreeEvent.started());
        await Future<void>.delayed(Duration.zero);
        repo.emit([
          _a('a', code: '1'),
          _a('a1', code: '11', parent: 'a'),
          _a('a11', code: '111', parent: 'a1'),
          _a('b', code: '2'),
          _a('b-leaf', code: '21', parent: 'b'),
        ]);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AccountTreeEvent.expandedAll());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final s = bloc.state as AccountTreeLoaded;
        // Every non-leaf must be in expandedIds: a (root non-leaf),
        // a1 (mid non-leaf), b (root non-leaf). 'b-leaf' and 'a11'
        // are leaves — excluded.
        expect(s.expandedIds, {'a', 'a1', 'b'});
      },
    );

    blocTest<AccountTreeBloc, AccountTreeState>(
      'CollapsedAll empties expandedIds',
      build: () => AccountTreeBloc(repository: repo, logger: _NoopLogger()),
      act: (bloc) async {
        bloc.add(const AccountTreeEvent.started());
        await Future<void>.delayed(Duration.zero);
        repo.emit([
          _a('root', code: '1000'),
          _a('child', code: '1100', parent: 'root'),
        ]);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AccountTreeEvent.collapsedAll());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final s = bloc.state as AccountTreeLoaded;
        expect(s.expandedIds, isEmpty);
      },
    );

    blocTest<AccountTreeBloc, AccountTreeState>(
      'feed re-emit preserves the user\'s expanded set (durability)',
      build: () => AccountTreeBloc(repository: repo, logger: _NoopLogger()),
      act: (bloc) async {
        bloc.add(const AccountTreeEvent.started());
        await Future<void>.delayed(Duration.zero);
        repo.emit([
          _a('root', code: '1000'),
          _a('child', code: '1100', parent: 'root'),
        ]);
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AccountTreeEvent.nodeToggled('child'));
        await Future<void>.delayed(Duration.zero);
        // Repo re-emits — same list, simulating a no-op refresh.
        repo.emit([
          _a('root', code: '1000'),
          _a('child', code: '1100', parent: 'root'),
        ]);
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        final s = bloc.state as AccountTreeLoaded;
        expect(
          s.expandedIds,
          {'root', 'child'},
          reason: 'feed updates must NOT reset the user\'s open branches',
        );
      },
    );

    blocTest<AccountTreeBloc, AccountTreeState>(
      'watch error → Failure (typed state, not unhandled exception)',
      build: () => AccountTreeBloc(repository: repo, logger: _NoopLogger()),
      act: (bloc) async {
        bloc.add(const AccountTreeEvent.started());
        await Future<void>.delayed(Duration.zero);
        repo.emitError(StateError('cache closed'));
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [
        const AccountTreeState.loading(),
        isA<AccountTreeFailure>()
            .having((s) => s.message, 'message', contains('cache closed')),
      ],
    );
  });
}
