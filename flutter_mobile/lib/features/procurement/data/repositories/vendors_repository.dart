import '../../entities/vendor.dart';
import '../../entities/vendor_scorecard.dart';

/// In-memory vendor seed (Slice 4.3.1).
///
/// Now flat (Module 4 refactor): folds the former `VendorsRepository`
/// abstract interface directly onto this class. The pure scorecard
/// math lives as [`computeVendorScorecard`] at the bottom of this file
/// so the repo stays a dumb data source.
class VendorsRepository {
  VendorsRepository();

  static final List<Vendor> _seed = <Vendor>[
    Vendor(
      id: 'v-001',
      name: 'Acme Supplies',
      taxId: 'TIN-100-201',
      email: 'orders@acme-supplies.example',
      phone: '+855 23 555 0101',
      address: '12 Russian Blvd, Phnom Penh',
      status: VendorStatus.active,
      onboardedAt: DateTime.utc(2024, 11, 3),
      contactPerson: 'Nita Sok',
    ),
    Vendor(
      id: 'v-002',
      name: 'Globex Electronics',
      taxId: 'TIN-100-411',
      email: 'sales@globex-elec.example',
      phone: '+855 23 555 0233',
      address: '88 Norodom Blvd, Phnom Penh',
      status: VendorStatus.active,
      onboardedAt: DateTime.utc(2025, 2, 14),
      contactPerson: 'Pisey Chan',
    ),
    Vendor(
      id: 'v-003',
      name: 'Initech Office',
      taxId: 'TIN-100-722',
      email: 'support@initech-off.example',
      phone: '+855 12 555 0399',
      address: '7 Sothearos Blvd, Phnom Penh',
      status: VendorStatus.onHold,
      onboardedAt: DateTime.utc(2025, 6, 1),
      notes: 'Late delivery on PO-2026-003 — under review.',
    ),
    Vendor(
      id: 'v-004',
      name: 'Wonka Industries',
      taxId: 'TIN-100-848',
      email: 'ar@wonka-ind.example',
      phone: '+855 78 555 0444',
      address: '102 Monivong Blvd, Phnom Penh',
      status: VendorStatus.archived,
      onboardedAt: DateTime.utc(2023, 1, 10),
      notes: 'Contract expired 2025-12-31, not renewed.',
    ),
  ];

  static final Map<String, VendorPerformanceStats> _stats = {
    'v-001': const VendorPerformanceStats(
      totalDeliveries: 28,
      onTimeDeliveries: 26,
      totalUnitsReceived: 412,
      defectiveUnits: 6,
      totalSpend: r'$48,200.00',
      openDisputes: 0,
    ),
    'v-002': const VendorPerformanceStats(
      totalDeliveries: 14,
      onTimeDeliveries: 13,
      totalUnitsReceived: 64,
      defectiveUnits: 1,
      totalSpend: r'$31,750.00',
      openDisputes: 0,
    ),
    'v-003': const VendorPerformanceStats(
      totalDeliveries: 11,
      onTimeDeliveries: 7,
      totalUnitsReceived: 220,
      defectiveUnits: 14,
      totalSpend: r'$8,900.00',
      openDisputes: 2,
    ),
    'v-004': const VendorPerformanceStats(
      totalDeliveries: 64,
      onTimeDeliveries: 60,
      totalUnitsReceived: 1280,
      defectiveUnits: 32,
      totalSpend: r'$112,400.00',
      openDisputes: 0,
    ),
  };

  static int _idCounter = 100;

  Future<List<Vendor>> getAll() async => List.unmodifiable(_seed);

  Stream<List<Vendor>> watchAll() async* {
    yield List.unmodifiable(_seed);
  }

  Future<Vendor?> findById(String id) async {
    for (final v in _seed) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// Persists a new vendor (Slice 4.3.2 onboarding form). The repo
  /// assigns the id; returns the persisted record.
  Future<Vendor> create(Vendor draft) async {
    _idCounter++;
    final id = 'v-${_idCounter.toString().padLeft(3, '0')}';
    final persisted = draft.copyWith(
      id: id,
      onboardedAt: DateTime.now().toUtc(),
    );
    _seed.insert(0, persisted);
    return persisted;
  }

  /// Returns raw performance stats for [vendorId] (Slice 4.3.3). The
  /// scorecard math lives in [`computeVendorScorecard`] so the repo
  /// stays a dumb data source.
  Future<VendorPerformanceStats> performanceStatsFor(String vendorId) async {
    return _stats[vendorId] ??
        const VendorPerformanceStats(
          totalDeliveries: 0,
          onTimeDeliveries: 0,
          totalUnitsReceived: 0,
          defectiveUnits: 0,
          totalSpend: r'$0.00',
          openDisputes: 0,
        );
  }
}

/// Pure scorecard math (Slice 4.3.3).
///
/// **Composite weights**: 60% on-time, 40% defect-free, then a flat
/// -10 per open dispute, capped at -20. The exact weights matter less
/// than the fact that they live in one tested place — buyers and ops
/// will iterate on these numbers without us touching widget code.
///
/// **Edge cases** (zero deliveries, zero units): treat the missing
/// data as "no signal" → 0.0%, not "perfect". A brand-new vendor with
/// no shipments yet shouldn't read as A-grade.
VendorScorecard computeVendorScorecard(VendorPerformanceStats stats) {
  final onTime = stats.totalDeliveries == 0
      ? 0.0
      : (stats.onTimeDeliveries / stats.totalDeliveries) * 100.0;
  final defect = stats.totalUnitsReceived == 0
      ? 0.0
      : (stats.defectiveUnits / stats.totalUnitsReceived) * 100.0;
  final defectFree = (100.0 - defect).clamp(0.0, 100.0);

  final base = (onTime * 0.6) + (defectFree * 0.4);
  final disputePenalty = (stats.openDisputes * 10).clamp(0, 20);
  final composite = (base - disputePenalty).clamp(0.0, 100.0);

  final grade = switch (composite) {
    >= 90.0 => VendorGrade.a,
    >= 75.0 => VendorGrade.b,
    >= 60.0 => VendorGrade.c,
    _ => VendorGrade.d,
  };

  return VendorScorecard(
    onTimeRatePct: onTime,
    defectRatePct: defect,
    compositeScore: composite,
    grade: grade,
    totalSpend: stats.totalSpend,
    openDisputes: stats.openDisputes,
  );
}
