import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission.freezed.dart';

/// Typed wrapper for a single permission token — e.g.
/// `'finance.invoice.create'`, `'inventory.stock.adjust'`, `'admin'`.
///
/// The wire format is the dotted string in [token]; this class layers
/// structured access (`feature`/`entity`/`action`) and wildcard matching
/// on top so the rest of the codebase stops scattering ad-hoc string
/// splits.
///
/// **Storage**: tokens round-trip as plain `String` through
/// `user_permissions` (drift). The `Permission` wrapper is constructed
/// at the data-layer boundary — see `PermissionsRepositoryImpl`.
@freezed
class Permission with _$Permission {
  const factory Permission({required String token}) = _Permission;

  const Permission._();

  /// Trims surrounding whitespace; otherwise no validation. Tokens are
  /// opaque to the client — the server is the canonical source.
  factory Permission.parse(String raw) => Permission(token: raw.trim());

  List<String> get _segments => token.split('.');

  /// First dotted segment — the broad area (`'finance'`, `'inventory'`,
  /// `'admin'`). Empty string for an empty token.
  String get feature => _segments.isNotEmpty ? _segments.first : '';

  /// Second dotted segment — the entity within the feature, when present.
  String? get entity => _segments.length >= 2 ? _segments[1] : null;

  /// Third dotted segment — the verb / action, when present.
  String? get action => _segments.length >= 3 ? _segments[2] : null;

  /// `true` when the token contains a `*` somewhere.
  bool get hasWildcard => token.contains('*');

  /// Does this permission *satisfy* the [required] one?
  ///
  /// Wildcard semantics:
  /// - **No wildcards** — exact-string match.
  /// - **Trailing `*`** — matches any continuation including dots.
  ///   `finance.*` grants `finance.invoice.create` AND `finance.report.export`.
  /// - **Mid `*`** — matches exactly one segment.
  ///   `finance.*.read` grants `finance.invoice.read` but not
  ///   `finance.invoice.create`.
  /// - **Bare `*`** — grants everything (super-admin).
  bool grants(Permission required) {
    if (!hasWildcard) return token == required.token;
    return _wildcardPattern(token).hasMatch(required.token);
  }
}

/// Read-side helper: does *any* permission in this iterable satisfy
/// [required]?
extension PermissionSetMatching on Iterable<Permission> {
  bool grant(Permission required) =>
      any((held) => held.grants(required));
}

/// Compiles a held-permission pattern into a regex once, anchored.
RegExp _wildcardPattern(String pattern) {
  final segments = pattern.split('.');
  final buffer = StringBuffer('^');
  for (var i = 0; i < segments.length; i++) {
    if (i > 0) buffer.write(r'\.');
    final seg = segments[i];
    if (seg == '*') {
      // Trailing star → "the rest" (inclusive of nested dots).
      // Mid star → exactly one segment (no dots).
      buffer.write(i == segments.length - 1 ? '.+' : '[^.]+');
    } else {
      buffer.write(RegExp.escape(seg));
    }
  }
  buffer.write(r'$');
  return RegExp(buffer.toString());
}
