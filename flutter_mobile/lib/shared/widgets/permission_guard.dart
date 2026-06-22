import 'package:flutter/widgets.dart';

import '../../core/di/injection.dart';
import '../../core/router/permissions_snapshot.dart';
import '../../features/auth/entities/permission.dart';

/// Conditionally renders [child] (or invokes [builder]) based on whether
/// the signed-in user holds the [required] permission.
///
/// **Companion to the route guard** (Slice 1.3.2): the route guard prevents
/// navigation to a permission-gated *page*; this widget hides or replaces
/// individual *controls* inside an otherwise-accessible page (e.g. a "delete"
/// button on an invoice list, or the "approve" action on a leave request).
///
/// Reads the same source as the route guard — [PermissionsSnapshot] —
/// so the verdict is consistent across both layers and the widget rebuilds
/// the moment the snapshot notifies (sign-in, sign-out, RBAC refresh).
///
/// **Two ways to use it**:
///
/// ```dart
/// // 1. Simple show/hide (default fallback is SizedBox.shrink()):
/// PermissionGuard(
///   required: const Permission(token: 'finance.invoice.delete'),
///   child: DeleteButton(),
/// )
///
/// // 2. Custom denied UI:
/// PermissionGuard(
///   required: const Permission(token: 'admin'),
///   denied: const Text('Admins only'),
///   child: AdminPanel(),
/// )
///
/// // 3. Full control — branch on the verdict yourself:
/// PermissionGuard.builder(
///   required: const Permission(token: 'admin'),
///   builder: (context, allowed) => allowed
///       ? FilledButton(onPressed: doIt, child: Text('Run'))
///       : OutlinedButton(onPressed: null, child: Text('Run')),
/// )
/// ```
///
/// The optional [snapshot] override exists so tests / Storybook can pump
/// in a fixed `PermissionsSnapshot` without standing up the full DI graph.
/// Production callers should leave it null and let the widget resolve via
/// `getIt`.
class PermissionGuard extends StatelessWidget {
  /// Show [child] when the user holds [required], else show [denied]
  /// (defaults to an invisible `SizedBox.shrink()`).
  const PermissionGuard({
    super.key,
    required this.required,
    required Widget this.child,
    this.denied,
    this.snapshot,
  }) : builder = null;

  /// Hand the verdict to a [builder] callback so callers can render
  /// "allowed" and "denied" branches with shared chrome (e.g. the same
  /// button, just disabled when denied).
  const PermissionGuard.builder({
    super.key,
    required this.required,
    required PermissionGuardBuilder this.builder,
    this.snapshot,
  })  : child = null,
        denied = null;

  final Permission required;
  final Widget? child;
  final Widget? denied;
  final PermissionGuardBuilder? builder;

  /// Test seam — when `null`, resolved from the global service locator.
  /// Production code should never pass this.
  final PermissionsSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final perms = snapshot ?? getIt<PermissionsSnapshot>();
    return ListenableBuilder(
      listenable: perms,
      builder: (context, _) {
        final allowed = perms.holds(required);
        if (builder != null) return builder!(context, allowed);
        return allowed ? child! : (denied ?? const SizedBox.shrink());
      },
    );
  }
}

/// Builder signature for [PermissionGuard.builder]. The `allowed` flag
/// reflects whether the snapshot's currently-cached set satisfies the
/// required permission.
typedef PermissionGuardBuilder = Widget Function(
  BuildContext context,
  bool allowed,
);
