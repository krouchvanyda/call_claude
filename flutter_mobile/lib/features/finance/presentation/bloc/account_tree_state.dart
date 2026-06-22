import 'package:freezed_annotation/freezed_annotation.dart';

import '../../entities/account_tree_node.dart';

part 'account_tree_state.freezed.dart';

/// State machine for [AccountTreeBloc] (Slice 3.1.1).
///
/// **Why expandedIds lives on state, not in the widget**: keeps the
/// expand/collapse choice durable across rebuilds (e.g. when a watch
/// emit refreshes the tree, the user's open branches stay open) and
/// lets future "remember last expanded" persistence plug into the
/// repository without touching widgets.
@freezed
sealed class AccountTreeState with _$AccountTreeState {
  const factory AccountTreeState.initial() = AccountTreeInitial;

  const factory AccountTreeState.loading() = AccountTreeLoading;

  const factory AccountTreeState.loaded({
    /// Pre-built roots (sorted, depth-tagged).
    required List<AccountTreeNode> roots,

    /// Set of account ids whose children are visible. Lookups are
    /// O(1) via Set<String>.
    required Set<String> expandedIds,
  }) = AccountTreeLoaded;

  const factory AccountTreeState.failure(String message) =
      AccountTreeFailure;
}
