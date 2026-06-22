import 'package:freezed_annotation/freezed_annotation.dart';

part 'global_search_event.freezed.dart';

/// Inputs to [GlobalSearchBloc] — kept tiny: the search bar emits one
/// event on every keystroke; the bloc handles debouncing internally
/// via an event transformer.
@freezed
sealed class GlobalSearchEvent with _$GlobalSearchEvent {
  /// User typed (or programmatic seed).
  const factory GlobalSearchEvent.queryChanged(String query) =
      GlobalSearchQueryChanged;

  /// Hard reset — bar closed, cleared, etc.
  const factory GlobalSearchEvent.cleared() = GlobalSearchCleared;
}
