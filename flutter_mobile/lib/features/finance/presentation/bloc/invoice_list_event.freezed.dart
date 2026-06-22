// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice_list_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$InvoiceListEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String query) searchChanged,
    required TResult Function(InvoiceStatus status) statusToggled,
    required TResult Function(InvoiceSort sort) sortChanged,
    required TResult Function(List<Invoice> all) feedUpdated,
    required TResult Function(String message) feedFailed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String query)? searchChanged,
    TResult? Function(InvoiceStatus status)? statusToggled,
    TResult? Function(InvoiceSort sort)? sortChanged,
    TResult? Function(List<Invoice> all)? feedUpdated,
    TResult? Function(String message)? feedFailed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String query)? searchChanged,
    TResult Function(InvoiceStatus status)? statusToggled,
    TResult Function(InvoiceSort sort)? sortChanged,
    TResult Function(List<Invoice> all)? feedUpdated,
    TResult Function(String message)? feedFailed,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(InvoiceListStarted value) started,
    required TResult Function(InvoiceListSearchChanged value) searchChanged,
    required TResult Function(InvoiceListStatusToggled value) statusToggled,
    required TResult Function(InvoiceListSortChanged value) sortChanged,
    required TResult Function(InvoiceListFeedUpdated value) feedUpdated,
    required TResult Function(InvoiceListFeedFailed value) feedFailed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(InvoiceListStarted value)? started,
    TResult? Function(InvoiceListSearchChanged value)? searchChanged,
    TResult? Function(InvoiceListStatusToggled value)? statusToggled,
    TResult? Function(InvoiceListSortChanged value)? sortChanged,
    TResult? Function(InvoiceListFeedUpdated value)? feedUpdated,
    TResult? Function(InvoiceListFeedFailed value)? feedFailed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(InvoiceListStarted value)? started,
    TResult Function(InvoiceListSearchChanged value)? searchChanged,
    TResult Function(InvoiceListStatusToggled value)? statusToggled,
    TResult Function(InvoiceListSortChanged value)? sortChanged,
    TResult Function(InvoiceListFeedUpdated value)? feedUpdated,
    TResult Function(InvoiceListFeedFailed value)? feedFailed,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvoiceListEventCopyWith<$Res> {
  factory $InvoiceListEventCopyWith(
    InvoiceListEvent value,
    $Res Function(InvoiceListEvent) then,
  ) = _$InvoiceListEventCopyWithImpl<$Res, InvoiceListEvent>;
}

/// @nodoc
class _$InvoiceListEventCopyWithImpl<$Res, $Val extends InvoiceListEvent>
    implements $InvoiceListEventCopyWith<$Res> {
  _$InvoiceListEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$InvoiceListStartedImplCopyWith<$Res> {
  factory _$$InvoiceListStartedImplCopyWith(
    _$InvoiceListStartedImpl value,
    $Res Function(_$InvoiceListStartedImpl) then,
  ) = __$$InvoiceListStartedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InvoiceListStartedImplCopyWithImpl<$Res>
    extends _$InvoiceListEventCopyWithImpl<$Res, _$InvoiceListStartedImpl>
    implements _$$InvoiceListStartedImplCopyWith<$Res> {
  __$$InvoiceListStartedImplCopyWithImpl(
    _$InvoiceListStartedImpl _value,
    $Res Function(_$InvoiceListStartedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InvoiceListStartedImpl implements InvoiceListStarted {
  const _$InvoiceListStartedImpl();

  @override
  String toString() {
    return 'InvoiceListEvent.started()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InvoiceListStartedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String query) searchChanged,
    required TResult Function(InvoiceStatus status) statusToggled,
    required TResult Function(InvoiceSort sort) sortChanged,
    required TResult Function(List<Invoice> all) feedUpdated,
    required TResult Function(String message) feedFailed,
  }) {
    return started();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String query)? searchChanged,
    TResult? Function(InvoiceStatus status)? statusToggled,
    TResult? Function(InvoiceSort sort)? sortChanged,
    TResult? Function(List<Invoice> all)? feedUpdated,
    TResult? Function(String message)? feedFailed,
  }) {
    return started?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String query)? searchChanged,
    TResult Function(InvoiceStatus status)? statusToggled,
    TResult Function(InvoiceSort sort)? sortChanged,
    TResult Function(List<Invoice> all)? feedUpdated,
    TResult Function(String message)? feedFailed,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(InvoiceListStarted value) started,
    required TResult Function(InvoiceListSearchChanged value) searchChanged,
    required TResult Function(InvoiceListStatusToggled value) statusToggled,
    required TResult Function(InvoiceListSortChanged value) sortChanged,
    required TResult Function(InvoiceListFeedUpdated value) feedUpdated,
    required TResult Function(InvoiceListFeedFailed value) feedFailed,
  }) {
    return started(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(InvoiceListStarted value)? started,
    TResult? Function(InvoiceListSearchChanged value)? searchChanged,
    TResult? Function(InvoiceListStatusToggled value)? statusToggled,
    TResult? Function(InvoiceListSortChanged value)? sortChanged,
    TResult? Function(InvoiceListFeedUpdated value)? feedUpdated,
    TResult? Function(InvoiceListFeedFailed value)? feedFailed,
  }) {
    return started?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(InvoiceListStarted value)? started,
    TResult Function(InvoiceListSearchChanged value)? searchChanged,
    TResult Function(InvoiceListStatusToggled value)? statusToggled,
    TResult Function(InvoiceListSortChanged value)? sortChanged,
    TResult Function(InvoiceListFeedUpdated value)? feedUpdated,
    TResult Function(InvoiceListFeedFailed value)? feedFailed,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started(this);
    }
    return orElse();
  }
}

abstract class InvoiceListStarted implements InvoiceListEvent {
  const factory InvoiceListStarted() = _$InvoiceListStartedImpl;
}

/// @nodoc
abstract class _$$InvoiceListSearchChangedImplCopyWith<$Res> {
  factory _$$InvoiceListSearchChangedImplCopyWith(
    _$InvoiceListSearchChangedImpl value,
    $Res Function(_$InvoiceListSearchChangedImpl) then,
  ) = __$$InvoiceListSearchChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String query});
}

/// @nodoc
class __$$InvoiceListSearchChangedImplCopyWithImpl<$Res>
    extends _$InvoiceListEventCopyWithImpl<$Res, _$InvoiceListSearchChangedImpl>
    implements _$$InvoiceListSearchChangedImplCopyWith<$Res> {
  __$$InvoiceListSearchChangedImplCopyWithImpl(
    _$InvoiceListSearchChangedImpl _value,
    $Res Function(_$InvoiceListSearchChangedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? query = null}) {
    return _then(
      _$InvoiceListSearchChangedImpl(
        null == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$InvoiceListSearchChangedImpl implements InvoiceListSearchChanged {
  const _$InvoiceListSearchChangedImpl(this.query);

  @override
  final String query;

  @override
  String toString() {
    return 'InvoiceListEvent.searchChanged(query: $query)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceListSearchChangedImpl &&
            (identical(other.query, query) || other.query == query));
  }

  @override
  int get hashCode => Object.hash(runtimeType, query);

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceListSearchChangedImplCopyWith<_$InvoiceListSearchChangedImpl>
  get copyWith =>
      __$$InvoiceListSearchChangedImplCopyWithImpl<
        _$InvoiceListSearchChangedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String query) searchChanged,
    required TResult Function(InvoiceStatus status) statusToggled,
    required TResult Function(InvoiceSort sort) sortChanged,
    required TResult Function(List<Invoice> all) feedUpdated,
    required TResult Function(String message) feedFailed,
  }) {
    return searchChanged(query);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String query)? searchChanged,
    TResult? Function(InvoiceStatus status)? statusToggled,
    TResult? Function(InvoiceSort sort)? sortChanged,
    TResult? Function(List<Invoice> all)? feedUpdated,
    TResult? Function(String message)? feedFailed,
  }) {
    return searchChanged?.call(query);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String query)? searchChanged,
    TResult Function(InvoiceStatus status)? statusToggled,
    TResult Function(InvoiceSort sort)? sortChanged,
    TResult Function(List<Invoice> all)? feedUpdated,
    TResult Function(String message)? feedFailed,
    required TResult orElse(),
  }) {
    if (searchChanged != null) {
      return searchChanged(query);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(InvoiceListStarted value) started,
    required TResult Function(InvoiceListSearchChanged value) searchChanged,
    required TResult Function(InvoiceListStatusToggled value) statusToggled,
    required TResult Function(InvoiceListSortChanged value) sortChanged,
    required TResult Function(InvoiceListFeedUpdated value) feedUpdated,
    required TResult Function(InvoiceListFeedFailed value) feedFailed,
  }) {
    return searchChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(InvoiceListStarted value)? started,
    TResult? Function(InvoiceListSearchChanged value)? searchChanged,
    TResult? Function(InvoiceListStatusToggled value)? statusToggled,
    TResult? Function(InvoiceListSortChanged value)? sortChanged,
    TResult? Function(InvoiceListFeedUpdated value)? feedUpdated,
    TResult? Function(InvoiceListFeedFailed value)? feedFailed,
  }) {
    return searchChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(InvoiceListStarted value)? started,
    TResult Function(InvoiceListSearchChanged value)? searchChanged,
    TResult Function(InvoiceListStatusToggled value)? statusToggled,
    TResult Function(InvoiceListSortChanged value)? sortChanged,
    TResult Function(InvoiceListFeedUpdated value)? feedUpdated,
    TResult Function(InvoiceListFeedFailed value)? feedFailed,
    required TResult orElse(),
  }) {
    if (searchChanged != null) {
      return searchChanged(this);
    }
    return orElse();
  }
}

abstract class InvoiceListSearchChanged implements InvoiceListEvent {
  const factory InvoiceListSearchChanged(final String query) =
      _$InvoiceListSearchChangedImpl;

  String get query;

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvoiceListSearchChangedImplCopyWith<_$InvoiceListSearchChangedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$InvoiceListStatusToggledImplCopyWith<$Res> {
  factory _$$InvoiceListStatusToggledImplCopyWith(
    _$InvoiceListStatusToggledImpl value,
    $Res Function(_$InvoiceListStatusToggledImpl) then,
  ) = __$$InvoiceListStatusToggledImplCopyWithImpl<$Res>;
  @useResult
  $Res call({InvoiceStatus status});
}

/// @nodoc
class __$$InvoiceListStatusToggledImplCopyWithImpl<$Res>
    extends _$InvoiceListEventCopyWithImpl<$Res, _$InvoiceListStatusToggledImpl>
    implements _$$InvoiceListStatusToggledImplCopyWith<$Res> {
  __$$InvoiceListStatusToggledImplCopyWithImpl(
    _$InvoiceListStatusToggledImpl _value,
    $Res Function(_$InvoiceListStatusToggledImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? status = null}) {
    return _then(
      _$InvoiceListStatusToggledImpl(
        null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as InvoiceStatus,
      ),
    );
  }
}

/// @nodoc

class _$InvoiceListStatusToggledImpl implements InvoiceListStatusToggled {
  const _$InvoiceListStatusToggledImpl(this.status);

  @override
  final InvoiceStatus status;

  @override
  String toString() {
    return 'InvoiceListEvent.statusToggled(status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceListStatusToggledImpl &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status);

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceListStatusToggledImplCopyWith<_$InvoiceListStatusToggledImpl>
  get copyWith =>
      __$$InvoiceListStatusToggledImplCopyWithImpl<
        _$InvoiceListStatusToggledImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String query) searchChanged,
    required TResult Function(InvoiceStatus status) statusToggled,
    required TResult Function(InvoiceSort sort) sortChanged,
    required TResult Function(List<Invoice> all) feedUpdated,
    required TResult Function(String message) feedFailed,
  }) {
    return statusToggled(status);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String query)? searchChanged,
    TResult? Function(InvoiceStatus status)? statusToggled,
    TResult? Function(InvoiceSort sort)? sortChanged,
    TResult? Function(List<Invoice> all)? feedUpdated,
    TResult? Function(String message)? feedFailed,
  }) {
    return statusToggled?.call(status);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String query)? searchChanged,
    TResult Function(InvoiceStatus status)? statusToggled,
    TResult Function(InvoiceSort sort)? sortChanged,
    TResult Function(List<Invoice> all)? feedUpdated,
    TResult Function(String message)? feedFailed,
    required TResult orElse(),
  }) {
    if (statusToggled != null) {
      return statusToggled(status);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(InvoiceListStarted value) started,
    required TResult Function(InvoiceListSearchChanged value) searchChanged,
    required TResult Function(InvoiceListStatusToggled value) statusToggled,
    required TResult Function(InvoiceListSortChanged value) sortChanged,
    required TResult Function(InvoiceListFeedUpdated value) feedUpdated,
    required TResult Function(InvoiceListFeedFailed value) feedFailed,
  }) {
    return statusToggled(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(InvoiceListStarted value)? started,
    TResult? Function(InvoiceListSearchChanged value)? searchChanged,
    TResult? Function(InvoiceListStatusToggled value)? statusToggled,
    TResult? Function(InvoiceListSortChanged value)? sortChanged,
    TResult? Function(InvoiceListFeedUpdated value)? feedUpdated,
    TResult? Function(InvoiceListFeedFailed value)? feedFailed,
  }) {
    return statusToggled?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(InvoiceListStarted value)? started,
    TResult Function(InvoiceListSearchChanged value)? searchChanged,
    TResult Function(InvoiceListStatusToggled value)? statusToggled,
    TResult Function(InvoiceListSortChanged value)? sortChanged,
    TResult Function(InvoiceListFeedUpdated value)? feedUpdated,
    TResult Function(InvoiceListFeedFailed value)? feedFailed,
    required TResult orElse(),
  }) {
    if (statusToggled != null) {
      return statusToggled(this);
    }
    return orElse();
  }
}

abstract class InvoiceListStatusToggled implements InvoiceListEvent {
  const factory InvoiceListStatusToggled(final InvoiceStatus status) =
      _$InvoiceListStatusToggledImpl;

  InvoiceStatus get status;

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvoiceListStatusToggledImplCopyWith<_$InvoiceListStatusToggledImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$InvoiceListSortChangedImplCopyWith<$Res> {
  factory _$$InvoiceListSortChangedImplCopyWith(
    _$InvoiceListSortChangedImpl value,
    $Res Function(_$InvoiceListSortChangedImpl) then,
  ) = __$$InvoiceListSortChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({InvoiceSort sort});
}

/// @nodoc
class __$$InvoiceListSortChangedImplCopyWithImpl<$Res>
    extends _$InvoiceListEventCopyWithImpl<$Res, _$InvoiceListSortChangedImpl>
    implements _$$InvoiceListSortChangedImplCopyWith<$Res> {
  __$$InvoiceListSortChangedImplCopyWithImpl(
    _$InvoiceListSortChangedImpl _value,
    $Res Function(_$InvoiceListSortChangedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? sort = null}) {
    return _then(
      _$InvoiceListSortChangedImpl(
        null == sort
            ? _value.sort
            : sort // ignore: cast_nullable_to_non_nullable
                  as InvoiceSort,
      ),
    );
  }
}

/// @nodoc

class _$InvoiceListSortChangedImpl implements InvoiceListSortChanged {
  const _$InvoiceListSortChangedImpl(this.sort);

  @override
  final InvoiceSort sort;

  @override
  String toString() {
    return 'InvoiceListEvent.sortChanged(sort: $sort)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceListSortChangedImpl &&
            (identical(other.sort, sort) || other.sort == sort));
  }

  @override
  int get hashCode => Object.hash(runtimeType, sort);

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceListSortChangedImplCopyWith<_$InvoiceListSortChangedImpl>
  get copyWith =>
      __$$InvoiceListSortChangedImplCopyWithImpl<_$InvoiceListSortChangedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String query) searchChanged,
    required TResult Function(InvoiceStatus status) statusToggled,
    required TResult Function(InvoiceSort sort) sortChanged,
    required TResult Function(List<Invoice> all) feedUpdated,
    required TResult Function(String message) feedFailed,
  }) {
    return sortChanged(sort);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String query)? searchChanged,
    TResult? Function(InvoiceStatus status)? statusToggled,
    TResult? Function(InvoiceSort sort)? sortChanged,
    TResult? Function(List<Invoice> all)? feedUpdated,
    TResult? Function(String message)? feedFailed,
  }) {
    return sortChanged?.call(sort);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String query)? searchChanged,
    TResult Function(InvoiceStatus status)? statusToggled,
    TResult Function(InvoiceSort sort)? sortChanged,
    TResult Function(List<Invoice> all)? feedUpdated,
    TResult Function(String message)? feedFailed,
    required TResult orElse(),
  }) {
    if (sortChanged != null) {
      return sortChanged(sort);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(InvoiceListStarted value) started,
    required TResult Function(InvoiceListSearchChanged value) searchChanged,
    required TResult Function(InvoiceListStatusToggled value) statusToggled,
    required TResult Function(InvoiceListSortChanged value) sortChanged,
    required TResult Function(InvoiceListFeedUpdated value) feedUpdated,
    required TResult Function(InvoiceListFeedFailed value) feedFailed,
  }) {
    return sortChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(InvoiceListStarted value)? started,
    TResult? Function(InvoiceListSearchChanged value)? searchChanged,
    TResult? Function(InvoiceListStatusToggled value)? statusToggled,
    TResult? Function(InvoiceListSortChanged value)? sortChanged,
    TResult? Function(InvoiceListFeedUpdated value)? feedUpdated,
    TResult? Function(InvoiceListFeedFailed value)? feedFailed,
  }) {
    return sortChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(InvoiceListStarted value)? started,
    TResult Function(InvoiceListSearchChanged value)? searchChanged,
    TResult Function(InvoiceListStatusToggled value)? statusToggled,
    TResult Function(InvoiceListSortChanged value)? sortChanged,
    TResult Function(InvoiceListFeedUpdated value)? feedUpdated,
    TResult Function(InvoiceListFeedFailed value)? feedFailed,
    required TResult orElse(),
  }) {
    if (sortChanged != null) {
      return sortChanged(this);
    }
    return orElse();
  }
}

abstract class InvoiceListSortChanged implements InvoiceListEvent {
  const factory InvoiceListSortChanged(final InvoiceSort sort) =
      _$InvoiceListSortChangedImpl;

  InvoiceSort get sort;

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvoiceListSortChangedImplCopyWith<_$InvoiceListSortChangedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$InvoiceListFeedUpdatedImplCopyWith<$Res> {
  factory _$$InvoiceListFeedUpdatedImplCopyWith(
    _$InvoiceListFeedUpdatedImpl value,
    $Res Function(_$InvoiceListFeedUpdatedImpl) then,
  ) = __$$InvoiceListFeedUpdatedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<Invoice> all});
}

/// @nodoc
class __$$InvoiceListFeedUpdatedImplCopyWithImpl<$Res>
    extends _$InvoiceListEventCopyWithImpl<$Res, _$InvoiceListFeedUpdatedImpl>
    implements _$$InvoiceListFeedUpdatedImplCopyWith<$Res> {
  __$$InvoiceListFeedUpdatedImplCopyWithImpl(
    _$InvoiceListFeedUpdatedImpl _value,
    $Res Function(_$InvoiceListFeedUpdatedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? all = null}) {
    return _then(
      _$InvoiceListFeedUpdatedImpl(
        null == all
            ? _value._all
            : all // ignore: cast_nullable_to_non_nullable
                  as List<Invoice>,
      ),
    );
  }
}

/// @nodoc

class _$InvoiceListFeedUpdatedImpl implements InvoiceListFeedUpdated {
  const _$InvoiceListFeedUpdatedImpl(final List<Invoice> all) : _all = all;

  final List<Invoice> _all;
  @override
  List<Invoice> get all {
    if (_all is EqualUnmodifiableListView) return _all;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_all);
  }

  @override
  String toString() {
    return 'InvoiceListEvent.feedUpdated(all: $all)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceListFeedUpdatedImpl &&
            const DeepCollectionEquality().equals(other._all, _all));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_all));

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceListFeedUpdatedImplCopyWith<_$InvoiceListFeedUpdatedImpl>
  get copyWith =>
      __$$InvoiceListFeedUpdatedImplCopyWithImpl<_$InvoiceListFeedUpdatedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String query) searchChanged,
    required TResult Function(InvoiceStatus status) statusToggled,
    required TResult Function(InvoiceSort sort) sortChanged,
    required TResult Function(List<Invoice> all) feedUpdated,
    required TResult Function(String message) feedFailed,
  }) {
    return feedUpdated(all);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String query)? searchChanged,
    TResult? Function(InvoiceStatus status)? statusToggled,
    TResult? Function(InvoiceSort sort)? sortChanged,
    TResult? Function(List<Invoice> all)? feedUpdated,
    TResult? Function(String message)? feedFailed,
  }) {
    return feedUpdated?.call(all);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String query)? searchChanged,
    TResult Function(InvoiceStatus status)? statusToggled,
    TResult Function(InvoiceSort sort)? sortChanged,
    TResult Function(List<Invoice> all)? feedUpdated,
    TResult Function(String message)? feedFailed,
    required TResult orElse(),
  }) {
    if (feedUpdated != null) {
      return feedUpdated(all);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(InvoiceListStarted value) started,
    required TResult Function(InvoiceListSearchChanged value) searchChanged,
    required TResult Function(InvoiceListStatusToggled value) statusToggled,
    required TResult Function(InvoiceListSortChanged value) sortChanged,
    required TResult Function(InvoiceListFeedUpdated value) feedUpdated,
    required TResult Function(InvoiceListFeedFailed value) feedFailed,
  }) {
    return feedUpdated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(InvoiceListStarted value)? started,
    TResult? Function(InvoiceListSearchChanged value)? searchChanged,
    TResult? Function(InvoiceListStatusToggled value)? statusToggled,
    TResult? Function(InvoiceListSortChanged value)? sortChanged,
    TResult? Function(InvoiceListFeedUpdated value)? feedUpdated,
    TResult? Function(InvoiceListFeedFailed value)? feedFailed,
  }) {
    return feedUpdated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(InvoiceListStarted value)? started,
    TResult Function(InvoiceListSearchChanged value)? searchChanged,
    TResult Function(InvoiceListStatusToggled value)? statusToggled,
    TResult Function(InvoiceListSortChanged value)? sortChanged,
    TResult Function(InvoiceListFeedUpdated value)? feedUpdated,
    TResult Function(InvoiceListFeedFailed value)? feedFailed,
    required TResult orElse(),
  }) {
    if (feedUpdated != null) {
      return feedUpdated(this);
    }
    return orElse();
  }
}

abstract class InvoiceListFeedUpdated implements InvoiceListEvent {
  const factory InvoiceListFeedUpdated(final List<Invoice> all) =
      _$InvoiceListFeedUpdatedImpl;

  List<Invoice> get all;

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvoiceListFeedUpdatedImplCopyWith<_$InvoiceListFeedUpdatedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$InvoiceListFeedFailedImplCopyWith<$Res> {
  factory _$$InvoiceListFeedFailedImplCopyWith(
    _$InvoiceListFeedFailedImpl value,
    $Res Function(_$InvoiceListFeedFailedImpl) then,
  ) = __$$InvoiceListFeedFailedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$InvoiceListFeedFailedImplCopyWithImpl<$Res>
    extends _$InvoiceListEventCopyWithImpl<$Res, _$InvoiceListFeedFailedImpl>
    implements _$$InvoiceListFeedFailedImplCopyWith<$Res> {
  __$$InvoiceListFeedFailedImplCopyWithImpl(
    _$InvoiceListFeedFailedImpl _value,
    $Res Function(_$InvoiceListFeedFailedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$InvoiceListFeedFailedImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$InvoiceListFeedFailedImpl implements InvoiceListFeedFailed {
  const _$InvoiceListFeedFailedImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'InvoiceListEvent.feedFailed(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceListFeedFailedImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceListFeedFailedImplCopyWith<_$InvoiceListFeedFailedImpl>
  get copyWith =>
      __$$InvoiceListFeedFailedImplCopyWithImpl<_$InvoiceListFeedFailedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String query) searchChanged,
    required TResult Function(InvoiceStatus status) statusToggled,
    required TResult Function(InvoiceSort sort) sortChanged,
    required TResult Function(List<Invoice> all) feedUpdated,
    required TResult Function(String message) feedFailed,
  }) {
    return feedFailed(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String query)? searchChanged,
    TResult? Function(InvoiceStatus status)? statusToggled,
    TResult? Function(InvoiceSort sort)? sortChanged,
    TResult? Function(List<Invoice> all)? feedUpdated,
    TResult? Function(String message)? feedFailed,
  }) {
    return feedFailed?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String query)? searchChanged,
    TResult Function(InvoiceStatus status)? statusToggled,
    TResult Function(InvoiceSort sort)? sortChanged,
    TResult Function(List<Invoice> all)? feedUpdated,
    TResult Function(String message)? feedFailed,
    required TResult orElse(),
  }) {
    if (feedFailed != null) {
      return feedFailed(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(InvoiceListStarted value) started,
    required TResult Function(InvoiceListSearchChanged value) searchChanged,
    required TResult Function(InvoiceListStatusToggled value) statusToggled,
    required TResult Function(InvoiceListSortChanged value) sortChanged,
    required TResult Function(InvoiceListFeedUpdated value) feedUpdated,
    required TResult Function(InvoiceListFeedFailed value) feedFailed,
  }) {
    return feedFailed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(InvoiceListStarted value)? started,
    TResult? Function(InvoiceListSearchChanged value)? searchChanged,
    TResult? Function(InvoiceListStatusToggled value)? statusToggled,
    TResult? Function(InvoiceListSortChanged value)? sortChanged,
    TResult? Function(InvoiceListFeedUpdated value)? feedUpdated,
    TResult? Function(InvoiceListFeedFailed value)? feedFailed,
  }) {
    return feedFailed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(InvoiceListStarted value)? started,
    TResult Function(InvoiceListSearchChanged value)? searchChanged,
    TResult Function(InvoiceListStatusToggled value)? statusToggled,
    TResult Function(InvoiceListSortChanged value)? sortChanged,
    TResult Function(InvoiceListFeedUpdated value)? feedUpdated,
    TResult Function(InvoiceListFeedFailed value)? feedFailed,
    required TResult orElse(),
  }) {
    if (feedFailed != null) {
      return feedFailed(this);
    }
    return orElse();
  }
}

abstract class InvoiceListFeedFailed implements InvoiceListEvent {
  const factory InvoiceListFeedFailed(final String message) =
      _$InvoiceListFeedFailedImpl;

  String get message;

  /// Create a copy of InvoiceListEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvoiceListFeedFailedImplCopyWith<_$InvoiceListFeedFailedImpl>
  get copyWith => throw _privateConstructorUsedError;
}
