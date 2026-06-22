/// Slice 9.2.2 / 9.1.5 — master catalog of permission scopes the app
/// knows how to render.
///
/// The server is the canonical source for *which* scopes are granted to
/// a user; this catalog is just the friendly-rendering layer so the
/// role editor and the My Roles & Permissions view can show all the
/// known scopes with human labels and module groupings, even the ones
/// the current user doesn't hold.
const List<String> knownPermissionScopes = <String>[
  'admin',
  'finance.*',
  'finance.read',
  'finance.approve',
  'inventory.*',
  'inventory.read',
  'sales.*',
  'sales.read',
  'hr.*',
  'hr.approve',
  'projects.*',
  'procurement.*',
  'procurement.approve',
];

/// Describes a scope for UI rendering — title, helper subtitle, and the
/// module it belongs to (used for the right-hand chip on the row).
class ScopeLabel {
  const ScopeLabel({
    required this.title,
    required this.subtitle,
    required this.module,
  });

  final String title;
  final String subtitle;
  final String module;
}

/// Maps a raw scope token (e.g. `finance.approve`) to a human label.
/// Unknown scopes fall back to a title-cased rendering so the page
/// never breaks on a new server-side scope.
ScopeLabel humanLabelForScope(String scope) {
  switch (scope) {
    case 'admin':
      return const ScopeLabel(
        title: 'Full administrator',
        subtitle: 'Unrestricted access across every module',
        module: 'Admin',
      );
    case 'finance.*':
      return const ScopeLabel(
        title: 'All finance operations',
        subtitle: 'Read, edit, approve invoices and journals',
        module: 'Finance',
      );
    case 'finance.read':
      return const ScopeLabel(
        title: 'View finance records',
        subtitle: 'Read invoices, journals, and reports',
        module: 'Finance',
      );
    case 'finance.approve':
      return const ScopeLabel(
        title: 'Approve invoices',
        subtitle: 'Sign off on pending finance approvals',
        module: 'Finance',
      );
    case 'inventory.*':
      return const ScopeLabel(
        title: 'All inventory operations',
        subtitle: 'Stock moves, transfers, cycle counts',
        module: 'Inventory',
      );
    case 'inventory.read':
      return const ScopeLabel(
        title: 'View inventory',
        subtitle: 'Read-only access to stock + movements',
        module: 'Inventory',
      );
    case 'sales.*':
      return const ScopeLabel(
        title: 'All sales operations',
        subtitle: 'Manage customers, quotations, orders',
        module: 'Sales',
      );
    case 'sales.read':
      return const ScopeLabel(
        title: 'View sales records',
        subtitle: 'Read-only access to customers + orders',
        module: 'Sales',
      );
    case 'hr.*':
      return const ScopeLabel(
        title: 'All HR operations',
        subtitle: 'Employees, leave, attendance, payroll',
        module: 'HR',
      );
    case 'hr.approve':
      return const ScopeLabel(
        title: 'Approve leave requests',
        subtitle: 'Decide on pending leave applications',
        module: 'HR',
      );
    case 'projects.*':
      return const ScopeLabel(
        title: 'All projects operations',
        subtitle: 'Manage projects, tasks, timesheets',
        module: 'Projects',
      );
    case 'procurement.*':
      return const ScopeLabel(
        title: 'All procurement operations',
        subtitle: 'Purchase requests, orders, goods receipts',
        module: 'Procurement',
      );
    case 'procurement.approve':
      return const ScopeLabel(
        title: 'Approve purchase requests',
        subtitle: 'Sign off on pending PR / PO approvals',
        module: 'Procurement',
      );
    default:
      // Fallback: split on '.' and title-case each part.
      final parts = scope.split('.');
      final pretty = parts.map((p) {
        if (p == '*') return 'All actions';
        if (p.isEmpty) return p;
        return '${p[0].toUpperCase()}${p.substring(1)}';
      }).join(' · ');
      return ScopeLabel(
        title: pretty.isEmpty ? scope : pretty,
        subtitle: scope,
        module: parts.isEmpty ? 'Other' : _titleCase(parts.first),
      );
  }
}

String _titleCase(String s) {
  if (s.isEmpty) return s;
  return '${s[0].toUpperCase()}${s.substring(1)}';
}
