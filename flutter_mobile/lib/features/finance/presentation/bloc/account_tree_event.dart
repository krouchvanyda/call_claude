import 'package:freezed_annotation/freezed_annotation.dart';

import '../../entities/account.dart';

part 'account_tree_event.freezed.dart';

/// Inputs to [AccountTreeBloc] (Slice 3.1.1).
///
/// Internal `_TreeUpdated` / `_TreeFailed` events are private-by-naming
/// (the bloc fires them from its own watch subscription); UI only
/// dispatches `Started` / `NodeToggled` / `ExpandedAll` / `CollapsedAll`.
@freezed
sealed class AccountTreeEvent with _$AccountTreeEvent {
  /// Subscribe to the repo's watch stream. Idempotent.
  const factory AccountTreeEvent.started() = AccountTreeStarted;

  /// Toggle a single node's expanded flag. Tap on a non-leaf row.
  const factory AccountTreeEvent.nodeToggled(String accountId) =
      AccountTreeNodeToggled;

  /// Toolbar action — expand every non-leaf node.
  const factory AccountTreeEvent.expandedAll() = AccountTreeExpandedAll;

  /// Toolbar action — collapse to roots only.
  const factory AccountTreeEvent.collapsedAll() = AccountTreeCollapsedAll;

  /// Internal — fired when the watch stream emits a fresh snapshot.
  /// Carries the raw flat list; the bloc rebuilds the tree.
  const factory AccountTreeEvent.feedUpdated(List<Account> accounts) =
      AccountTreeFeedUpdated;

  /// Internal — fired when the watch stream errors.
  const factory AccountTreeEvent.feedFailed(String message) =
      AccountTreeFeedFailed;
}
