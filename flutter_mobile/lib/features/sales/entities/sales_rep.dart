/// Sales rep / account executive — keyed to the `actor` field on
/// [`ActivityEvent`] so the leaderboard math can attribute orders to
/// reps without a separate "owner" column on every order header.
class SalesRep {
  const SalesRep({
    required this.id,
    required this.name,
    required this.targetAmount,
  });

  final String id;
  final String name;

  /// Pre-formatted period target (e.g. `r'$60,000.00'`). Used to
  /// render the attainment bar on the leaderboard tile.
  final String targetAmount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalesRep &&
          other.id == id &&
          other.name == name &&
          other.targetAmount == targetAmount;

  @override
  int get hashCode => Object.hash(id, name, targetAmount);
}
