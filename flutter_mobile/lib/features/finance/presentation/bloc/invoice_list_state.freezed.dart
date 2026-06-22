// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$InvoiceListState {
  /// Pre-filtered, pre-sorted view-ready list. Empty until the first
  /// feed emit lands.
  List<Invoice> get visible => throw _privateConstructorUsedError;

  /// Raw list off the repository — kept around so toolbar changes
  /// re-derive [visible] without a round-trip.
  List<Invoice> get source => throw _privateConstructorUsedError;
  String get searchQuery => throw _privateConstructorUsedError;

  /// Empty set = no filter (show every status).
  Set<InvoiceStatus> get statusFilter => throw _privateConstructorUsedError;
  InvoiceSort get sort => throw _privateConstructorUsedError;

  /// `true` from `Started` until the first feed emit. Distinct from
  /// `source.isEmpty` because a *successful* zero-row fetch is not
  /// loading.
  bool get isLoading => throw _privateConstructorUsedError;

  /// Last watch-stream error message; `null` when healthy.
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of InvoiceListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InvoiceListStateCopyWith<InvoiceListState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvoiceListStateCopyWith<$Res> {
  factory $InvoiceListStateCopyWith(
    InvoiceListState value,
    $Res Function(InvoiceListState) then,
  ) = _$InvoiceListStateCopyWithImpl<$Res, InvoiceListState>;
  @useResult
  $Res call({
    List<Invoice> visible,
    List<Invoice> source,
    String searchQuery,
    Set<InvoiceStatus> statusFilter,
    InvoiceSort sort,
    bool isLoading,
    String? errorMessage,
  });
}

/// @nodoc
class _$InvoiceListStateCopyWithImpl<$Res, $Val extends InvoiceListState>
    implements $InvoiceListStateCopyWith<$Res> {
  _$InvoiceListStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InvoiceListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? visible = null,
    Object? source = null,
    Object? searchQuery = null,
    Object? statusFilter = null,
    Object? sort = null,
    Object? isLoading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            visible: null == visible
                ? _value.visible
                : visible // ignore: cast_nullable_to_non_nullable
                      as List<Invoice>,
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as List<Invoice>,
            searchQuery: null == searchQuery
                ? _value.searchQuery
                : searchQuery // ignore: cast_nullable_to_non_nullable
                      as String,
            statusFilter: null == statusFilter
                ? _value.statusFilter
                : statusFilter // ignore: cast_nullable_to_non_nullable
                      as Set<InvoiceStatus>,
            sort: null == sort
                ? _value.sort
                : sort // ignore: cast_nullable_to_non_nullable
                      as InvoiceSort,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InvoiceListStateImplCopyWith<$Res>
    implements $InvoiceListStateCopyWith<$Res> {
  factory _$$InvoiceListStateImplCopyWith(
    _$InvoiceListStateImpl value,
    $Res Function(_$InvoiceListStateImpl) then,
  ) = __$$InvoiceListStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Invoice> visible,
    List<Invoice> source,
    String searchQuery,
    Set<InvoiceStatus> statusFilter,
    InvoiceSort sort,
    bool isLoading,
    String? errorMessage,
  });
}

/// @nodoc
class __$$InvoiceListStateImplCopyWithImpl<$Res>
    extends _$InvoiceListStateCopyWithImpl<$Res, _$InvoiceListStateImpl>
    implements _$$InvoiceListStateImplCopyWith<$Res> {
  __$$InvoiceListStateImplCopyWithImpl(
    _$InvoiceListStateImpl _value,
    $Res Function(_$InvoiceListStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InvoiceListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? visible = null,
    Object? source = null,
    Object? searchQuery = null,
    Object? statusFilter = null,
    Object? sort = null,
    Object? isLoading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$InvoiceListStateImpl(
        visible: null == visible
            ? _value._visible
            : visible // ignore: cast_nullable_to_non_nullable
                  as List<Invoice>,
        source: null == source
            ? _value._source
            : source // ignore: cast_nullable_to_non_nullable
                  as List<Invoice>,
        searchQuery: null == searchQuery
            ? _value.searchQuery
            : searchQuery // ignore: cast_nullable_to_non_nullable
                  as String,
        statusFilter: null == statusFilter
            ? _value._statusFilter
            : statusFilter // ignore: cast_nullable_to_non_nullable
                  as Set<InvoiceStatus>,
        sort: null == sort
            ? _value.sort
            : sort // ignore: cast_nullable_to_non_nullable
                  as InvoiceSort,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$InvoiceListStateImpl implements _InvoiceListState {
  const _$InvoiceListStateImpl({
    final List<Invoice> visible = const <Invoice>[],
    final List<Invoice> source = const <Invoice>[],
    this.searchQuery = '',
    final Set<InvoiceStatus> statusFilter = const <InvoiceStatus>{},
    this.sort = InvoiceSort.issuedDateDesc,
    this.isLoading = true,
    this.errorMessage,
  }) : _visible = visible,
       _source = source,
       _statusFilter = statusFilter;

  /// Pre-filtered, pre-sorted view-ready list. Empty until the first
  /// feed emit lands.
  final List<Invoice> _visible;

  /// Pre-filtered, pre-sorted view-ready list. Empty until the first
  /// feed emit lands.
  @override
  @JsonKey()
  List<Invoice> get visible {
    if (_visible is EqualUnmodifiableListView) return _visible;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_visible);
  }

  /// Raw list off the repository — kept around so toolbar changes
  /// re-derive [visible] without a round-trip.
  final List<Invoice> _source;

  /// Raw list off the repository — kept around so toolbar changes
  /// re-derive [visible] without a round-trip.
  @override
  @JsonKey()
  List<Invoice> get source {
    if (_source is EqualUnmodifiableListView) return _source;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_source);
  }

  @override
  @JsonKey()
  final String searchQuery;

  /// Empty set = no filter (show every status).
  final Set<InvoiceStatus> _statusFilter;

  /// Empty set = no filter (show every status).
  @override
  @JsonKey()
  Set<InvoiceStatus> get statusFilter {
    if (_statusFilter is EqualUnmodifiableSetView) return _statusFilter;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_statusFilter);
  }

  @override
  @JsonKey()
  final InvoiceSort sort;

  /// `true` from `Started` until the first feed emit. Distinct from
  /// `source.isEmpty` because a *successful* zero-row fetch is not
  /// loading.
  @override
  @JsonKey()
  final bool isLoading;

  /// Last watch-stream error message; `null` when healthy.
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'InvoiceListState(visible: $visible, source: $source, searchQuery: $searchQuery, statusFilter: $statusFilter, sort: $sort, isLoading: $isLoading, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceListStateImpl &&
            const DeepCollectionEquality().equals(other._visible, _visible) &&
            const DeepCollectionEquality().equals(other._source, _source) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            const DeepCollectionEquality().equals(
              other._statusFilter,
              _statusFilter,
            ) &&
            (identical(other.sort, sort) || other.sort == sort) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_visible),
    const DeepCollectionEquality().hash(_source),
    searchQuery,
    const DeepCollectionEquality().hash(_statusFilter),
    sort,
    isLoading,
    errorMessage,
  );

  /// Create a copy of InvoiceListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceListStateImplCopyWith<_$InvoiceListStateImpl> get copyWith =>
      __$$InvoiceListStateImplCopyWithImpl<_$InvoiceListStateImpl>(
        this,
        _$identity,
      );
}

abstract class _InvoiceListState implements InvoiceListState {
  const factory _InvoiceListState({
    final List<Invoice> visible,
    final List<Invoice> source,
    final String searchQuery,
    final Set<InvoiceStatus> statusFilter,
    final InvoiceSort sort,
    final bool isLoading,
    final String? errorMessage,
  }) = _$InvoiceListStateImpl;

  /// Pre-filtered, pre-sorted view-ready list. Empty until the first
  /// feed emit lands.
  @override
  List<Invoice> get visible;

  /// Raw list off the repository — kept around so toolbar changes
  /// re-derive [visible] without a round-trip.
  @override
  List<Invoice> get source;
  @override
  String get searchQuery;

  /// Empty set = no filter (show every status).
  @override
  Set<InvoiceStatus> get statusFilter;
  @override
  InvoiceSort get sort;

  /// `true` from `Started` until the first feed emit. Distinct from
  /// `source.isEmpty` because a *successful* zero-row fetch is not
  /// loading.
  @override
  bool get isLoading;

  /// Last watch-stream error message; `null` when healthy.
  @override
  String? get errorMessage;

  /// Create a copy of InvoiceListState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvoiceListStateImplCopyWith<_$InvoiceListStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
