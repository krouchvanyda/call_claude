import 'package:freezed_annotation/freezed_annotation.dart';

part 'conflict.freezed.dart';

/// Input to a [ConflictPolicy] — the local and server views of the same
/// entity, plus optional last-modified timestamps.
///
/// Producers (the sync engine in 0.4.3) hand a `Conflict<T>` to the
/// resolver when the server reports a divergence (typically via 409, ETag
/// mismatch, or a returned representation that differs from what we sent).
@freezed
class Conflict<T> with _$Conflict<T> {
  const factory Conflict({
    required T local,
    required T server,

    /// Last local mutation time (the optimistic update). Optional because
    /// not every table carries an `updatedAt` column — without it the
    /// last-write-wins policy falls back to its configured tiebreaker.
    DateTime? localUpdatedAt,
    DateTime? serverUpdatedAt,
  }) = _Conflict<T>;
}
