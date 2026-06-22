import '../entities/api_environment.dart';
import '../entities/audit_log_entry.dart';
import '../entities/device_session.dart';
import '../entities/managed_user.dart';

/// Single source of demo data for Module 9 (Settings & Admin).
class SettingsSeed {
  static final List<Role> roles = <Role>[
    Role(
      id: 'role-admin',
      name: 'Admin',
      description: 'Full access — manage users, roles, configuration.',
      permissionTokens: const [
        'admin',
        'finance.*',
        'inventory.*',
        'sales.*',
        'hr.*',
        'projects.*',
      ],
      isSystem: true,
    ),
    Role(
      id: 'role-viewer',
      name: 'Viewer',
      description: 'Read-only access across all modules.',
      permissionTokens: const [
        'finance.read',
        'inventory.read',
        'sales.read',
      ],
      isSystem: true,
    ),
    Role(
      id: 'role-finance-mgr',
      name: 'Finance Manager',
      description: 'Approve invoices, view reports.',
      permissionTokens: const [
        'finance.*',
        'finance.approve',
      ],
    ),
    Role(
      id: 'role-warehouse',
      name: 'Warehouse',
      description: 'Inventory + scanning operations.',
      permissionTokens: const ['inventory.*'],
    ),
  ];

  static final List<ManagedUser> users = <ManagedUser>[
    ManagedUser(
      id: 'user-demo',
      email: 'demo@erp.example',
      name: 'Demo Approver',
      status: ManagedUserStatus.active,
      roleIds: const ['role-admin'],
      createdAt: DateTime.utc(2024, 4, 1),
      lastSeenAt: DateTime.utc(2026, 5, 15, 9, 0),
    ),
    ManagedUser(
      id: 'user-002',
      email: 'pisey.chan@erp.example',
      name: 'Pisey Chan',
      status: ManagedUserStatus.active,
      roleIds: const ['role-finance-mgr'],
      createdAt: DateTime.utc(2024, 6, 10),
      lastSeenAt: DateTime.utc(2026, 5, 14, 16, 30),
    ),
    ManagedUser(
      id: 'user-003',
      email: 'rithy.heng@erp.example',
      name: 'Rithy Heng',
      status: ManagedUserStatus.active,
      roleIds: const ['role-warehouse'],
      createdAt: DateTime.utc(2024, 8, 22),
      lastSeenAt: DateTime.utc(2026, 5, 14, 17, 15),
    ),
    ManagedUser(
      id: 'user-004',
      email: 'new.hire@erp.example',
      name: 'New Hire',
      status: ManagedUserStatus.invited,
      roleIds: const ['role-viewer'],
      createdAt: DateTime.utc(2026, 5, 13),
    ),
    ManagedUser(
      id: 'user-005',
      email: 'former.staff@erp.example',
      name: 'Former Staff',
      status: ManagedUserStatus.suspended,
      roleIds: const ['role-viewer'],
      createdAt: DateTime.utc(2024, 1, 5),
      lastSeenAt: DateTime.utc(2025, 12, 20),
    ),
  ];

  static final List<ApiEnvironment> environments = <ApiEnvironment>[
    ApiEnvironment(
      id: 'env-prod',
      name: 'Production',
      baseUrl: 'http://localhost:8080/api/v1',
      isBuiltIn: true,
    ),
    ApiEnvironment(
      id: 'env-staging',
      name: 'Staging',
      baseUrl: 'http://localhost:8080/api/v1',
      isBuiltIn: true,
    ),
    ApiEnvironment(
      id: 'env-local',
      name: 'Local dev',
      baseUrl: 'http://localhost:8080/api/v1',
      isBuiltIn: true,
    ),
  ];

  static const String defaultEnvironmentId = 'env-prod';

  static final List<DeviceSession> sessions = <DeviceSession>[
    DeviceSession(
      id: 'sess-001',
      deviceLabel: 'Pixel 7 Pro',
      platform: 'Android 14',
      lastActiveAt: DateTime.utc(2026, 5, 15, 9, 0),
      signedInAt: DateTime.utc(2026, 5, 1, 8, 15),
      location: 'Phnom Penh, KH',
      isCurrent: true,
      ipAddress: '203.0.113.10',
    ),
    DeviceSession(
      id: 'sess-002',
      deviceLabel: 'iPad Pro 11"',
      platform: 'iPadOS 17',
      lastActiveAt: DateTime.utc(2026, 5, 14, 17, 30),
      signedInAt: DateTime.utc(2026, 4, 22, 14, 0),
      location: 'Phnom Penh, KH',
      isCurrent: false,
      ipAddress: '203.0.113.10',
    ),
    DeviceSession(
      id: 'sess-003',
      deviceLabel: 'MacBook Pro 14"',
      platform: 'macOS 14 (web)',
      lastActiveAt: DateTime.utc(2026, 5, 13, 11, 45),
      signedInAt: DateTime.utc(2026, 3, 18, 9, 0),
      location: 'Phnom Penh, KH',
      isCurrent: false,
      ipAddress: '198.51.100.42',
    ),
  ];

  static final List<AuditLogEntry> auditLog = <AuditLogEntry>[
    AuditLogEntry(
      id: 'aud-001',
      actorId: 'user-demo',
      actorName: 'Demo Approver',
      action: AuditAction.signIn,
      targetType: 'session',
      targetId: 'sess-001',
      targetLabel: 'Pixel 7 Pro',
      occurredAt: DateTime.utc(2026, 5, 15, 9, 0),
    ),
    AuditLogEntry(
      id: 'aud-002',
      actorId: 'user-demo',
      actorName: 'Demo Approver',
      action: AuditAction.approve,
      targetType: 'invoice',
      targetId: 'inv-014',
      targetLabel: 'INV-014 — Acme Corp',
      occurredAt: DateTime.utc(2026, 5, 14, 14, 30),
    ),
    AuditLogEntry(
      id: 'aud-003',
      actorId: 'user-002',
      actorName: 'Pisey Chan',
      action: AuditAction.reject,
      targetType: 'leave_request',
      targetId: 'lv-004',
      targetLabel: 'Khmer New Year extension',
      occurredAt: DateTime.utc(2026, 3, 22, 11, 0),
      detail: 'Coverage gap — please reschedule',
    ),
    AuditLogEntry(
      id: 'aud-004',
      actorId: 'user-demo',
      actorName: 'Demo Approver',
      action: AuditAction.permissionChange,
      targetType: 'user',
      targetId: 'user-003',
      targetLabel: 'Rithy Heng',
      occurredAt: DateTime.utc(2026, 5, 10, 10, 15),
      detail: 'Added inventory.* role',
    ),
    AuditLogEntry(
      id: 'aud-005',
      actorId: 'user-002',
      actorName: 'Pisey Chan',
      action: AuditAction.update,
      targetType: 'invoice',
      targetId: 'inv-016',
      targetLabel: 'INV-016 — Initech',
      occurredAt: DateTime.utc(2026, 5, 8, 14, 0),
    ),
    AuditLogEntry(
      id: 'aud-006',
      actorId: 'user-demo',
      actorName: 'Demo Approver',
      action: AuditAction.create,
      targetType: 'role',
      targetId: 'role-finance-mgr',
      targetLabel: 'Finance Manager',
      occurredAt: DateTime.utc(2026, 4, 15, 9, 0),
    ),
    AuditLogEntry(
      id: 'aud-007',
      actorId: 'user-003',
      actorName: 'Rithy Heng',
      action: AuditAction.exportData,
      targetType: 'report',
      targetId: 'inv-month-end',
      targetLabel: 'Inventory month-end',
      occurredAt: DateTime.utc(2026, 4, 30, 17, 45),
    ),
    AuditLogEntry(
      id: 'aud-008',
      actorId: 'user-005',
      actorName: 'Former Staff',
      action: AuditAction.signOut,
      targetType: 'session',
      targetId: 'sess-old',
      targetLabel: 'iPhone 12',
      occurredAt: DateTime.utc(2025, 12, 20, 17, 0),
    ),
  ];
}
