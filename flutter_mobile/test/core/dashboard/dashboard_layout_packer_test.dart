import 'package:erp_mobile/core/dashboard/dashboard_layout_packer.dart';
import 'package:test/test.dart';

void main() {
  group('packIntoRows', () {
    test('empty input → no rows', () {
      expect(packIntoRows(const [], 3), isEmpty);
    });

    test('every slot is span-1, exactly fills one row at a time', () {
      // 5 slots × span-1 into 3 cols → [3, 2]
      expect(
        packIntoRows(const [1, 1, 1, 1, 1], 3),
        [
          [0, 1, 2],
          [3, 4],
        ],
      );
    });

    test('a single span-N slot consumes one row by itself', () {
      // span 3 into 3 cols → single full row.
      expect(packIntoRows(const [3], 3), [
        [0],
      ]);
    });

    test('mixed spans wrap when the next slot would overflow', () {
      // Trace: 1+2=3 fills row 0; span-2 starts row 1 (cur=2); span-1
      // tops it off (cur=3 == maxCols, exact fit, no new row).
      expect(
        packIntoRows(const [1, 2, 2, 1], 3),
        [
          [0, 1],
          [2, 3],
        ],
      );
    });

    test(
        'wrap on overflow: 1+2 fills, then span-3 cannot share row, then '
        'spans 2+2 split across two rows', () {
      // Spans: 1, 2, 3, 2, 2 with maxCols = 3.
      // row 0: [0]=1, [1]=2 (3 == maxCols, exact fit)
      // row 1: [2]=3 (alone)
      // row 2: [3]=2, [4]=2 → 2+2 overflows, wrap → [3] alone, then [4]
      expect(
        packIntoRows(const [1, 2, 3, 2, 2], 3),
        [
          [0, 1],
          [2],
          [3],
          [4],
        ],
      );
    });

    test('oversize span is clamped to maxCols + gets its own row', () {
      // span 5 with maxCols 3 → effective 3 → fills its own row.
      expect(
        packIntoRows(const [1, 5, 1], 3),
        [
          [0],
          [1],
          [2],
        ],
      );
    });

    test('zero / negative spans are clamped up to 1 (never zero-width)', () {
      // Two zero-spans + a one-span into 2 cols → all three fit row 0
      // (each contributes 1).
      expect(
        packIntoRows(const [0, -1, 1], 2),
        [
          [0, 1],
          [2],
        ],
      );
    });

    test('order is preserved across rows (reading order)', () {
      final rows = packIntoRows(const [2, 1, 2, 1, 1, 1], 3);
      // Flattening must reproduce the original indexes in order.
      final flat = [for (final r in rows) ...r];
      expect(flat, [0, 1, 2, 3, 4, 5]);
    });

    test('exact fit closes the row cleanly without an empty trailing row', () {
      // 2 + 2 = 4 → row 0 full at maxCols=4. No empty row added.
      expect(
        packIntoRows(const [2, 2], 4),
        [
          [0, 1],
        ],
      );
    });

    test('single column (compact extreme) forces one slot per row', () {
      expect(
        packIntoRows(const [1, 2, 1], 1),
        [
          [0],
          [1],
          [2],
        ],
      );
    });

    test('throws on maxCols < 1 (caller bug, not silent fallback)', () {
      expect(() => packIntoRows(const [1], 0), throwsArgumentError);
      expect(() => packIntoRows(const [1], -2), throwsArgumentError);
    });
  });

  group('effectiveSpan', () {
    test('clamps oversize down to maxCols', () {
      expect(effectiveSpan(5, 3), 3);
    });

    test('clamps zero / negative up to 1', () {
      expect(effectiveSpan(0, 4), 1);
      expect(effectiveSpan(-1, 4), 1);
    });

    test('passes through in-range values unchanged', () {
      expect(effectiveSpan(2, 4), 2);
      expect(effectiveSpan(4, 4), 4);
    });
  });
}
