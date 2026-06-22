import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/search_result.dart';

part 'global_search_state.freezed.dart';

/// State machine for the global search bar.
///
/// **State carries the query** so the widget can decorate the bar (loader
/// near the input, "no results for X" copy) without keeping its own
/// shadow copy.
@freezed
sealed class GlobalSearchState with _$GlobalSearchState {
  /// No query yet — show empty / suggestion content.
  const factory GlobalSearchState.idle() = GlobalSearchIdle;

  /// Query is in flight. The previous results (if any) are intentionally
  /// dropped so a stale list doesn't sit under a fresh spinner.
  const factory GlobalSearchState.loading(String query) =
      GlobalSearchLoading;

  /// Query completed — [groups] preserves provider order so the section
  /// list is stable. Empty groups are filtered out by the use case, so
  /// `groups.isEmpty` here means "nothing matched at all".
  const factory GlobalSearchState.success({
    required String query,
    required List<SearchResultGroup> groups,
  }) = GlobalSearchSuccess;

  /// All providers threw, or the use case itself blew up. Per-provider
  /// failures are absorbed; the user only sees this on a total wipeout.
  const factory GlobalSearchState.failure({
    required String query,
    required String message,
  }) = GlobalSearchFailure;
}
