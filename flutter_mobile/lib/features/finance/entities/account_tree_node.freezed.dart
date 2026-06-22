// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_tree_node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AccountTreeNode {
  Account get account => throw _privateConstructorUsedError;

  /// Child nodes, sorted by `account.code` (the builder's
  /// responsibility). Empty list = leaf.
  List<AccountTreeNode> get children => throw _privateConstructorUsedError;

  /// Depth from the root (root = 0). Pre-computed at build time so
  /// the renderer doesn't recurse for every tile's indentation.
  int get depth => throw _privateConstructorUsedError;

  /// Create a copy of AccountTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountTreeNodeCopyWith<AccountTreeNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountTreeNodeCopyWith<$Res> {
  factory $AccountTreeNodeCopyWith(
    AccountTreeNode value,
    $Res Function(AccountTreeNode) then,
  ) = _$AccountTreeNodeCopyWithImpl<$Res, AccountTreeNode>;
  @useResult
  $Res call({Account account, List<AccountTreeNode> children, int depth});

  $AccountCopyWith<$Res> get account;
}

/// @nodoc
class _$AccountTreeNodeCopyWithImpl<$Res, $Val extends AccountTreeNode>
    implements $AccountTreeNodeCopyWith<$Res> {
  _$AccountTreeNodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? account = null,
    Object? children = null,
    Object? depth = null,
  }) {
    return _then(
      _value.copyWith(
            account: null == account
                ? _value.account
                : account // ignore: cast_nullable_to_non_nullable
                      as Account,
            children: null == children
                ? _value.children
                : children // ignore: cast_nullable_to_non_nullable
                      as List<AccountTreeNode>,
            depth: null == depth
                ? _value.depth
                : depth // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }

  /// Create a copy of AccountTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AccountCopyWith<$Res> get account {
    return $AccountCopyWith<$Res>(_value.account, (value) {
      return _then(_value.copyWith(account: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AccountTreeNodeImplCopyWith<$Res>
    implements $AccountTreeNodeCopyWith<$Res> {
  factory _$$AccountTreeNodeImplCopyWith(
    _$AccountTreeNodeImpl value,
    $Res Function(_$AccountTreeNodeImpl) then,
  ) = __$$AccountTreeNodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Account account, List<AccountTreeNode> children, int depth});

  @override
  $AccountCopyWith<$Res> get account;
}

/// @nodoc
class __$$AccountTreeNodeImplCopyWithImpl<$Res>
    extends _$AccountTreeNodeCopyWithImpl<$Res, _$AccountTreeNodeImpl>
    implements _$$AccountTreeNodeImplCopyWith<$Res> {
  __$$AccountTreeNodeImplCopyWithImpl(
    _$AccountTreeNodeImpl _value,
    $Res Function(_$AccountTreeNodeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? account = null,
    Object? children = null,
    Object? depth = null,
  }) {
    return _then(
      _$AccountTreeNodeImpl(
        account: null == account
            ? _value.account
            : account // ignore: cast_nullable_to_non_nullable
                  as Account,
        children: null == children
            ? _value._children
            : children // ignore: cast_nullable_to_non_nullable
                  as List<AccountTreeNode>,
        depth: null == depth
            ? _value.depth
            : depth // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$AccountTreeNodeImpl extends _AccountTreeNode {
  const _$AccountTreeNodeImpl({
    required this.account,
    final List<AccountTreeNode> children = const <AccountTreeNode>[],
    this.depth = 0,
  }) : _children = children,
       super._();

  @override
  final Account account;

  /// Child nodes, sorted by `account.code` (the builder's
  /// responsibility). Empty list = leaf.
  final List<AccountTreeNode> _children;

  /// Child nodes, sorted by `account.code` (the builder's
  /// responsibility). Empty list = leaf.
  @override
  @JsonKey()
  List<AccountTreeNode> get children {
    if (_children is EqualUnmodifiableListView) return _children;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_children);
  }

  /// Depth from the root (root = 0). Pre-computed at build time so
  /// the renderer doesn't recurse for every tile's indentation.
  @override
  @JsonKey()
  final int depth;

  @override
  String toString() {
    return 'AccountTreeNode(account: $account, children: $children, depth: $depth)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountTreeNodeImpl &&
            (identical(other.account, account) || other.account == account) &&
            const DeepCollectionEquality().equals(other._children, _children) &&
            (identical(other.depth, depth) || other.depth == depth));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    account,
    const DeepCollectionEquality().hash(_children),
    depth,
  );

  /// Create a copy of AccountTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountTreeNodeImplCopyWith<_$AccountTreeNodeImpl> get copyWith =>
      __$$AccountTreeNodeImplCopyWithImpl<_$AccountTreeNodeImpl>(
        this,
        _$identity,
      );
}

abstract class _AccountTreeNode extends AccountTreeNode {
  const factory _AccountTreeNode({
    required final Account account,
    final List<AccountTreeNode> children,
    final int depth,
  }) = _$AccountTreeNodeImpl;
  const _AccountTreeNode._() : super._();

  @override
  Account get account;

  /// Child nodes, sorted by `account.code` (the builder's
  /// responsibility). Empty list = leaf.
  @override
  List<AccountTreeNode> get children;

  /// Depth from the root (root = 0). Pre-computed at build time so
  /// the renderer doesn't recurse for every tile's indentation.
  @override
  int get depth;

  /// Create a copy of AccountTreeNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountTreeNodeImplCopyWith<_$AccountTreeNodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
