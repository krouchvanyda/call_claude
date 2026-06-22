/// Slice 7.3.2 — line item kinds that compose a payslip.
///
/// `earning` / `overtime` add to gross pay; `deduction` / `tax` subtract.
/// Keep this enum closed so the summary routines (Slice 7.3.3) can
/// switch exhaustively.
enum PayslipLineKind { earning, overtime, deduction, tax }

class PayslipLine {
  const PayslipLine({
    required this.id,
    required this.label,
    required this.kind,
    required this.amount,
  });

  final String id;
  final String label;
  final PayslipLineKind kind;

  /// Pre-formatted (e.g. `r'$2,400.00'`). Summary routines parse this
  /// once with [readAmount].
  final String amount;

  PayslipLine copyWith({
    String? id,
    String? label,
    PayslipLineKind? kind,
    String? amount,
  }) =>
      PayslipLine(
        id: id ?? this.id,
        label: label ?? this.label,
        kind: kind ?? this.kind,
        amount: amount ?? this.amount,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayslipLine &&
          other.id == id &&
          other.label == label &&
          other.kind == kind &&
          other.amount == amount;

  @override
  int get hashCode => Object.hash(id, label, kind, amount);
}

/// Strips currency punctuation off pre-formatted [amount] strings so
/// summary routines can do arithmetic. Returns `0` for malformed input
/// so the totals chart never crashes on a stray dash.
double readAmount(String formatted) {
  final cleaned = formatted.replaceAll(RegExp(r'[^0-9.\-]'), '');
  return double.tryParse(cleaned) ?? 0;
}

class Payslip {
  const Payslip({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.periodStart,
    required this.periodEnd,
    required this.issuedAt,
    required this.lineItems,
    required this.grossPay,
    required this.totalDeductions,
    required this.netPay,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime issuedAt;
  final List<PayslipLine> lineItems;

  /// Pre-formatted, pre-computed by the seed (or the payroll engine when
  /// one lands).
  final String grossPay;
  final String totalDeductions;
  final String netPay;

  Payslip copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? issuedAt,
    List<PayslipLine>? lineItems,
    String? grossPay,
    String? totalDeductions,
    String? netPay,
  }) =>
      Payslip(
        id: id ?? this.id,
        employeeId: employeeId ?? this.employeeId,
        employeeName: employeeName ?? this.employeeName,
        periodStart: periodStart ?? this.periodStart,
        periodEnd: periodEnd ?? this.periodEnd,
        issuedAt: issuedAt ?? this.issuedAt,
        lineItems: lineItems ?? this.lineItems,
        grossPay: grossPay ?? this.grossPay,
        totalDeductions: totalDeductions ?? this.totalDeductions,
        netPay: netPay ?? this.netPay,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Payslip) return false;
    if (other.id != id ||
        other.employeeId != employeeId ||
        other.employeeName != employeeName ||
        other.periodStart != periodStart ||
        other.periodEnd != periodEnd ||
        other.issuedAt != issuedAt ||
        other.grossPay != grossPay ||
        other.totalDeductions != totalDeductions ||
        other.netPay != netPay) {
      return false;
    }
    if (other.lineItems.length != lineItems.length) return false;
    for (var i = 0; i < lineItems.length; i++) {
      if (other.lineItems[i] != lineItems[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        employeeId,
        employeeName,
        periodStart,
        periodEnd,
        issuedAt,
        Object.hashAll(lineItems),
        grossPay,
        totalDeductions,
        netPay,
      );
}
