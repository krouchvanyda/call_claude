import 'package:erp_mobile/core/export/csv_writer.dart';
import 'package:test/test.dart';

void main() {
  group('CsvWriter.escapeField', () {
    test('plain text passes through untouched', () {
      expect(CsvWriter.escapeField('hello'), 'hello');
    });

    test('null becomes empty string', () {
      expect(CsvWriter.escapeField(null), '');
    });

    test('field with comma is quoted', () {
      expect(CsvWriter.escapeField('a, b'), '"a, b"');
    });

    test('field with double-quote doubles the quote AND wraps', () {
      expect(CsvWriter.escapeField('he said "hi"'), '"he said ""hi"""');
    });

    test('embedded newline forces quoting', () {
      expect(CsvWriter.escapeField('line1\nline2'), '"line1\nline2"');
    });

    test('embedded carriage return forces quoting', () {
      expect(CsvWriter.escapeField('line1\rline2'), '"line1\rline2"');
    });

    test('non-string values get .toString()', () {
      expect(CsvWriter.escapeField(42), '42');
      expect(CsvWriter.escapeField(3.14), '3.14');
    });
  });

  group('CsvWriter.encodeRow', () {
    test('joins with commas, no wrapping when none needed', () {
      expect(CsvWriter.encodeRow(['a', 'b', 'c']), 'a,b,c');
    });

    test('mixes plain + quoted in the same row', () {
      expect(
        CsvWriter.encodeRow(['safe', 'has,comma', 'plain']),
        'safe,"has,comma",plain',
      );
    });
  });

  group('CsvWriter.encode', () {
    test('header + rows → \\r\\n-terminated document', () {
      final out = CsvWriter.encode(
        header: ['code', 'name'],
        rows: [
          ['1100', 'Bank'],
          ['1110', 'Petty cash'],
        ],
      );
      expect(out, 'code,name\r\n1100,Bank\r\n1110,Petty cash\r\n');
    });

    test('empty rows still emits the header line', () {
      final out = CsvWriter.encode(header: ['x', 'y'], rows: const []);
      expect(out, 'x,y\r\n');
    });

    test('round-trip: a row with a comma + quotes survives', () {
      final out = CsvWriter.encode(
        header: ['msg'],
        rows: [
          [r'he said "wow, that''s a lot"'],
        ],
      );
      expect(out.contains(r'"he said ""wow, that''s a lot"""'), isTrue);
    });
  });
}
