import 'dart:async';

import '../../entities/payslip.dart';
import '../hr_seed.dart';

/// Slice 7.3.2 — payslip history (read-only in the demo).
class PayslipsRepository {
  PayslipsRepository();

  static final List<Payslip> _seed = List<Payslip>.of(HrSeed.payslips);

  final StreamController<List<Payslip>> _changes =
      StreamController<List<Payslip>>.broadcast();

  Future<List<Payslip>> getForEmployee(String employeeId) async {
    final out = _seed.where((p) => p.employeeId == employeeId).toList()
      ..sort((a, b) => b.periodEnd.compareTo(a.periodEnd));
    return List.unmodifiable(out);
  }

  Stream<List<Payslip>> watchForEmployee(String employeeId) async* {
    yield await getForEmployee(employeeId);
    yield* _changes.stream.map(
      (all) {
        final out = all.where((p) => p.employeeId == employeeId).toList()
          ..sort((a, b) => b.periodEnd.compareTo(a.periodEnd));
        return List<Payslip>.unmodifiable(out);
      },
    );
  }

  Future<Payslip?> findById(String id) async {
    for (final p in _seed) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// Slice 7.3.3 — bucketed totals over the line items of one or more
/// payslips. The page uses the per-payslip flavour for the detail view
/// and the aggregate flavour for the period summary card.
class PayslipBuckets {
  const PayslipBuckets({
    required this.earnings,
    required this.overtime,
    required this.deductions,
    required this.tax,
  });

  final double earnings;
  final double overtime;
  final double deductions;
  final double tax;

  double get grossPay => earnings + overtime;
  double get totalDeductions => deductions + tax;
  double get netPay => grossPay - totalDeductions;
}

PayslipBuckets summarizePayslip(Payslip slip) =>
    _bucketsFrom(slip.lineItems);

PayslipBuckets summarizePeriod(Iterable<Payslip> slips) {
  final all = <PayslipLine>[
    for (final s in slips) ...s.lineItems,
  ];
  return _bucketsFrom(all);
}

PayslipBuckets _bucketsFrom(Iterable<PayslipLine> lines) {
  double earnings = 0;
  double overtime = 0;
  double deductions = 0;
  double tax = 0;
  for (final l in lines) {
    final amount = readAmount(l.amount);
    switch (l.kind) {
      case PayslipLineKind.earning:
        earnings += amount;
      case PayslipLineKind.overtime:
        overtime += amount;
      case PayslipLineKind.deduction:
        deductions += amount;
      case PayslipLineKind.tax:
        tax += amount;
    }
  }
  return PayslipBuckets(
    earnings: earnings,
    overtime: overtime,
    deductions: deductions,
    tax: tax,
  );
}

/// Cheap pre-formatter for the summary card. Matches the seed style
/// (`$1,234.56`). Leaves negative values with a leading dash.
String formatAmount(double v) {
  final isNeg = v < 0;
  final abs = v.abs();
  final whole = abs.truncate();
  final frac = (abs - whole) * 100;
  final fracStr = frac.round().toString().padLeft(2, '0');
  final wholeStr = whole
      .toString()
      .split('')
      .reversed
      .toList()
      .asMap()
      .entries
      .map((e) => (e.key > 0 && e.key % 3 == 0) ? '${e.value},' : e.value)
      .toList()
      .reversed
      .join();
  return '${isNeg ? '-' : ''}\$$wholeStr.$fracStr';
}
