import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../../core/utils/logger/app_logger.dart';
import '../../data/repositories/accounts_repository.dart';
import '../../entities/account.dart';
import '../../entities/account_tree_node.dart';
import 'account_tree_event.dart';
import 'account_tree_state.dart';

/// Bloc behind the chart-of-accounts page (Slice 3.1.1).
///
/// **Watch-only data flow** — same pattern as the notification inbox
/// bloc: subscribes to [AccountsRepository.watchAll] on `Started`,
/// rebuilds the tree on each emit, surfaces user toggles immediately
/// without a round-trip through the repository.
///
/// **Default expansion**: roots are expanded out of the gate so the
/// user sees the type rollups (Assets / Liabilities / …) without
/// having to tap to discover them. Deeper levels start collapsed.
class AccountTreeBloc extends Bloc<AccountTreeEvent, AccountTreeState> {
  AccountTreeBloc({
    required AccountsRepository repository,
    required AppLogger logger,
  })  : _repository = repository,
        _logger = logger,
        super(const AccountTreeState.initial()) {
    on<AccountTreeStarted>(_onStarted);
    on<AccountTreeNodeToggled>(_onToggled);
    on<AccountTreeExpandedAll>(_onExpandedAll);
    on<AccountTreeCollapsedAll>(_onCollapsedAll);
    on<AccountTreeFeedUpdated>(_onFeedUpdated);
    on<AccountTreeFeedFailed>(_onFeedFailed);
  }

  final AccountsRepository _repository;
  final AppLogger _logger;
  StreamSubscription<List<Account>>? _sub;

  Future<void> _onStarted(
    AccountTreeStarted event,
    Emitter<AccountTreeState> emit,
  ) async {
    if (_sub != null) return;
    emit(const AccountTreeState.loading());
    _sub = _repository.watchAll().listen(
          (list) => add(AccountTreeEvent.feedUpdated(list)),
          onError: (Object e) =>
              add(AccountTreeEvent.feedFailed(e.toString())),
        );
  }

  void _onFeedUpdated(
    AccountTreeFeedUpdated event,
    Emitter<AccountTreeState> emit,
  ) {
    final roots = buildAccountTree(
      event.accounts,
      onCycle: (id) => _logger.warn('accounts: cycle suppressed for $id'),
    );
    final prev = state;
    final expandedIds = prev is AccountTreeLoaded
        ? prev.expandedIds
        : _defaultExpansion(roots);
    emit(AccountTreeState.loaded(roots: roots, expandedIds: expandedIds));
  }

  void _onFeedFailed(
    AccountTreeFeedFailed event,
    Emitter<AccountTreeState> emit,
  ) {
    emit(AccountTreeState.failure(event.message));
  }

  void _onToggled(
    AccountTreeNodeToggled event,
    Emitter<AccountTreeState> emit,
  ) {
    final s = state;
    if (s is! AccountTreeLoaded) return;
    final next = Set<String>.of(s.expandedIds);
    if (!next.remove(event.accountId)) next.add(event.accountId);
    emit(s.copyWith(expandedIds: next));
  }

  void _onExpandedAll(
    AccountTreeExpandedAll event,
    Emitter<AccountTreeState> emit,
  ) {
    final s = state;
    if (s is! AccountTreeLoaded) return;
    final ids = <String>{};
    void walk(List<AccountTreeNode> nodes) {
      for (final n in nodes) {
        if (!n.isLeaf) {
          ids.add(n.account.id);
          walk(n.children);
        }
      }
    }

    walk(s.roots);
    emit(s.copyWith(expandedIds: ids));
  }

  void _onCollapsedAll(
    AccountTreeCollapsedAll event,
    Emitter<AccountTreeState> emit,
  ) {
    final s = state;
    if (s is! AccountTreeLoaded) return;
    emit(s.copyWith(expandedIds: const <String>{}));
  }

  /// Roots-only expansion — feels right on first open: the user sees
  /// the top-level rollups without having to tap to discover them,
  /// and avoids dumping a hundred deep leaves on screen.
  static Set<String> _defaultExpansion(List<AccountTreeNode> roots) {
    return {
      for (final r in roots)
        if (!r.isLeaf) r.account.id,
    };
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
