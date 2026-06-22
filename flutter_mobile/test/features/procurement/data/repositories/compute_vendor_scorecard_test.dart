import 'package:erp_mobile/features/procurement/data/repositories/vendors_repository.dart';
import 'package:erp_mobile/features/procurement/entities/vendor_scorecard.dart';
import 'package:test/test.dart';

VendorPerformanceStats _stats({
  int totalDeliveries = 10,
  int onTimeDeliveries = 10,
  int totalUnitsReceived = 100,
  int defectiveUnits = 0,
  int openDisputes = 0,
  String spend = r'$0',
}) =>
    VendorPerformanceStats(
      totalDeliveries: totalDeliveries,
      onTimeDeliveries: onTimeDeliveries,
      totalUnitsReceived: totalUnitsReceived,
      defectiveUnits: defectiveUnits,
      totalSpend: spend,
      openDisputes: openDisputes,
    );

void main() {
  group('computeVendorScorecard', () {
    test('perfect record → composite 100, grade A', () {
      final s = computeVendorScorecard(_stats());
      expect(s.onTimeRatePct, 100);
      expect(s.defectRatePct, 0);
      expect(s.compositeScore, 100);
      expect(s.grade, VendorGrade.a);
    });

    test('zero deliveries → on-time 0% (no inflated score)', () {
      final s = computeVendorScorecard(_stats(
        totalDeliveries: 0,
        onTimeDeliveries: 0,
      ));
      expect(s.onTimeRatePct, 0);
      // defect-free is 100 (no units received → no defects measured)
      // composite = 0*0.6 + 100*0.4 = 40 → grade D
      expect(s.compositeScore, 40);
      expect(s.grade, VendorGrade.d);
    });

    test('zero units received → defect-free 100% (no false-defect)', () {
      final s = computeVendorScorecard(_stats(totalUnitsReceived: 0));
      expect(s.defectRatePct, 0);
    });

    test('mixed — 80% on-time, 5% defect, no disputes', () {
      final s = computeVendorScorecard(_stats(
        totalDeliveries: 10,
        onTimeDeliveries: 8,
        totalUnitsReceived: 100,
        defectiveUnits: 5,
      ));
      expect(s.onTimeRatePct, 80);
      expect(s.defectRatePct, 5);
      // 80*0.6 + 95*0.4 = 48 + 38 = 86 → B
      expect(s.compositeScore, closeTo(86, 0.001));
      expect(s.grade, VendorGrade.b);
    });

    test('open disputes flat-penalise composite, capped at -20', () {
      // 100% on-time, 0% defect → base 100. 1 dispute → 90 (still A).
      final one = computeVendorScorecard(_stats(openDisputes: 1));
      expect(one.compositeScore, 90);
      expect(one.grade, VendorGrade.a);

      // 5 disputes → cap at -20 → 80 (B).
      final five = computeVendorScorecard(_stats(openDisputes: 5));
      expect(five.compositeScore, 80);
      expect(five.grade, VendorGrade.b);
    });

    test('grade thresholds — boundary checks', () {
      // composite exactly 90 → A, 89.99 → B
      final a = computeVendorScorecard(_stats(
        totalDeliveries: 10,
        onTimeDeliveries: 10,
        totalUnitsReceived: 100,
        defectiveUnits: 25, // defect 25 → defect-free 75
        // 100*0.6 + 75*0.4 = 60 + 30 = 90
      ));
      expect(a.compositeScore, 90);
      expect(a.grade, VendorGrade.a);
    });

    test('totalSpend and openDisputes pass through', () {
      final s = computeVendorScorecard(_stats(
        spend: r'$1,234.56',
        openDisputes: 3,
      ));
      expect(s.totalSpend, r'$1,234.56');
      expect(s.openDisputes, 3);
    });
  });
}
