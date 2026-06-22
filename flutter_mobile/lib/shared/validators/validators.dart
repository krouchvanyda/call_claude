/// Pure-Dart field validators (Slice 3.2.3).
///
/// Each returns `null` on valid input, an error code (string) on
/// invalid. Codes — not localised messages — so the UI maps them via
/// AppLocalizations and the validator stays Flutter-free.
class Validators {
  Validators._();

  /// Empty / whitespace-only → `'required'`.
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return 'required';
    return null;
  }

  /// Numeric > 0. Empty / non-numeric → `'invalid_number'`; ≤0 → `'must_be_positive'`.
  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'required';
    final n = num.tryParse(value.trim());
    if (n == null) return 'invalid_number';
    if (n <= 0) return 'must_be_positive';
    return null;
  }

  /// Numeric ≥ 0 (zero allowed — useful for tax / discount fields).
  static String? nonNegativeNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'required';
    final n = num.tryParse(value.trim());
    if (n == null) return 'invalid_number';
    if (n < 0) return 'must_be_non_negative';
    return null;
  }

  /// `due >= issued`. Both required.
  static String? dueOnOrAfterIssued({
    required DateTime? issued,
    required DateTime? due,
  }) {
    if (issued == null || due == null) return 'required';
    if (due.isBefore(issued)) return 'due_before_issued';
    return null;
  }

  /// Composes multiple validators — returns the first non-null error.
  static String? compose(String? value, List<String? Function(String?)> rules) {
    for (final rule in rules) {
      final err = rule(value);
      if (err != null) return err;
    }
    return null;
  }

  /// RFC-5322-lite email check (Slice 4.3.2). Empty → `'required'`.
  /// Anything missing `local@domain.tld` shape → `'invalid_email'`.
  /// Strict RFC compliance is intentionally NOT attempted — that
  /// catches real human typos at the cost of false positives in real
  /// (uncommon) addresses, and gets revisited when we hook up
  /// server-side verification.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'required';
    final v = value.trim();
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!re.hasMatch(v)) return 'invalid_email';
    return null;
  }
}
