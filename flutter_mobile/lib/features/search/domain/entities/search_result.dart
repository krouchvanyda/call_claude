import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_result.freezed.dart';

/// One row returned by a [SearchProvider]'s response (Slice 2.1.3).
///
/// Pure value type — no Flutter imports — so the entity is unit-testable
/// in pure-Dart tests. Icons and result-rendering live in the widget
/// layer (the UI looks `iconOf` up by [providerId]).
///
/// **Navigation**: the result carries no page reference. Consumers
/// dispatch on `(providerId, id)`: for `providerId == 'modules'`, the
/// UI looks up the matching [ModuleShortcut] in [ModuleShortcutCatalog]
/// by `id` and calls its `builder()` via `ConfigRouter`.
@freezed
class SearchResult with _$SearchResult {
  const factory SearchResult({
    /// Stable identity within [providerId] — used for keying widgets,
    /// deduping within a provider's own response, AND for the consumer
    /// to look up the destination page (e.g. by matching against
    /// [ModuleShortcutCatalog]).
    required String id,

    /// Primary line shown in the result tile.
    required String title,

    /// Optional secondary line (record code, customer name, etc.).
    String? subtitle,

    /// Which provider produced this row — drives grouping in the UI
    /// AND the navigation dispatch.
    required String providerId,
  }) = _SearchResult;
}

/// Aggregated response from one provider: the provider id + its rows.
/// `FederatedSearchUseCase` returns a list of these so the UI can
/// render section headers per module.
@freezed
class SearchResultGroup with _$SearchResultGroup {
  const factory SearchResultGroup({
    required String providerId,
    required List<SearchResult> results,
  }) = _SearchResultGroup;
}
