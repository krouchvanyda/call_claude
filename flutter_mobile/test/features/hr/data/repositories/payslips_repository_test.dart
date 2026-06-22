import 'package:erp_mobile/features/hr/data/repositories/payslips_repository.dart';
import 'package:erp_mobile/features/hr/entities/payslip.dart';
import 'package:test/test.dart';

PayslipLine _l(PayslipLineKind k, String amount) =>
    PayslipLine(id: 'l-${amount.hashCode}', label: 'l', kind: k, amount: amount);

Payslip _slip(List<PayslipLine> lines) => Payslip(
      id: 'p',
      employeeId: 'emp',
      employeeName: 'A',
      periodStart: DateTime.utc(2026, 4, 1),
      periodEnd: DateTime.utc(2026, 4, 30),
      issuedAt: DateTime.utc(2026, 5, 1),
      lineItems: lines,
      grossPay: r'$0',
      totalDeductions: r'$0',
      netPay: r'$0',
    );

void main() {
  group('summarizePayslip', () {
    test('buckets earnings vs overtime vs deductions vs tax', () {
      final s = _slip([
        _l(PayslipLineKind.earning, r'$1,000'),
        _l(PayslipLineKind.overtime, r'$200'),
        _l(PayslipLineKind.deduction, r'$50'),
        _l(PayslipLineKind.tax, r'$150'),
      ]);
      final b = summarizePayslip(s);
      expect(b.earnings, 1000);
      expect(b.overtime, 200);
      expect(b.deductions, 50);
      expect(b.tax, 150);
      expect(b.grossPay, 1200);
      expect(b.totalDeductions, 200);
      expect(b.netPay, 1000);
    });

    test('malformed amounts contribute 0 (no crash)', () {
      final s = _slip([
        _l(PayslipLineKind.earning, '—'),
      ]);
      expect(summarizePayslip(s).earnings, 0);
    });
  });

  group('summarizePeriod', () {
    test('aggregates across slips', () {
      final out = summarizePeriod([
        _slip([_l(PayslipLineKind.earning, r'$1,000')]),
        _slip([_l(PayslipLineKind.earning, r'$1,200')]),
      ]);
      expect(out.earnings, 2200);
    });

    test('empty input → all zeros', () {
      final out = summarizePeriod(const []);
      expect(out.earnings, 0);
      expect(out.netPay, 0);
    });
  });

  group('readAmount', () {
    test('strips currency punctuation', () {
      expect(readAmount(r'$1,234.56'), 1234.56);
      expect(readAmount(r'-$50'), -50);
    });

    test('returns 0 for malformed input', () {
      expect(readAmount('—'), 0);
    });
  });

  group('formatAmount', () {
    test('thousands separator + 2 decimals', () {
      expect(formatAmount(1234.5), r'$1,234.50');
      expect(formatAmount(50), r'$50.00');
    });

    test('preserves negatives', () {
      expect(formatAmount(-50.25), r'-$50.25');
    });

    test('over a thousand groups by three', () {
      expect(formatAmount(1234567.89), r'$1,234,567.89');
    });
  });
}
