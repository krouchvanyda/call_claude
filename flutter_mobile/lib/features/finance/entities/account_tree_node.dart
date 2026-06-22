import 'package:freezed_annotation/freezed_annotation.dart';

import 'account.dart';

part 'account_tree_node.freezed.dart';

/// Recursive tree node — one [Account] plus its expanded child nodes
/// (Slice 3.1.1).
///
/// **Why a separate type, not just `Account` with children**: keeps
/// the [Account] entity flat / DTO-shaped (matches the wire + drift
/// row layout). The tree structure is a presentation concern computed
/// from a flat list by `buildAccountTree`; bundling children into the
/// entity itself would force every persistence layer to deal with
/// nested writes.
///
/// **Pure data**: no Flutter, no drift. Construction is the tree
/// builder's job; consumers only read.
@freezed
class AccountTreeNode with _$AccountTreeNode {
  const factory AccountTreeNode({
    required Account account,

    /// Child nodes, sorted by `account.code` (the builder's
    /// responsibility). Empty list = leaf.
    @Default(<AccountTreeNode>[]) List<AccountTreeNode> children,

    /// Depth from the root (root = 0). Pre-computed at build time so
    /// the renderer doesn't recurse for every tile's indentation.
    @Default(0) int depth,
  }) = _AccountTreeNode;

  const AccountTreeNode._();

  /// `true` when this node has no children — drives the chevron
  /// visibility in the tree tile.
  bool get isLeaf => children.isEmpty;
}
