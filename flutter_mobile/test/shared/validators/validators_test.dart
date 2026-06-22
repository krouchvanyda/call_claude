import 'package:erp_mobile/shared/validators/validators.dart';
import 'package:test/test.dart';

void main() {
  group('Validators.required', () {
    test('null / empty / whitespace → "required"', () {
      expect(Validators.required(null), 'required');
      expect(Validators.required(''), 'required');
      expect(Validators.required('   '), 'required');
    });
    test('non-empty → null', () {
      expect(Validators.required('x'), isNull);
    });
  });

  group('Validators.positiveNumber', () {
    test('empty → "required"', () {
      expect(Validators.positiveNumber(null), 'required');
      expect(Validators.positiveNumber(''), 'required');
    });
    test('non-numeric → "invalid_number"', () {
      expect(Validators.positiveNumber('abc'), 'invalid_number');
      expect(Validators.positiveNumber('1.2.3'), 'invalid_number');
    });
    test('zero or negative → "must_be_positive"', () {
      expect(Validators.positiveNumber('0'), 'must_be_positive');
      expect(Validators.positiveNumber('-1'), 'must_be_positive');
      expect(Validators.positiveNumber('-0.01'), 'must_be_positive');
    });
    test('positive (incl. fractional) → null', () {
      expect(Validators.positiveNumber('1'), isNull);
      expect(Validators.positiveNumber('0.5'), isNull);
      expect(Validators.positiveNumber('1234.56'), isNull);
    });
    test('whitespace around the number is tolerated', () {
      expect(Validators.positiveNumber('  3  '), isNull);
    });
  });

  group('Validators.nonNegativeNumber', () {
    test('zero is valid (unlike positiveNumber)', () {
      expect(Validators.nonNegativeNumber('0'), isNull);
      expect(Validators.nonNegativeNumber('0.0'), isNull);
    });
    test('negative → "must_be_non_negative"', () {
      expect(Validators.nonNegativeNumber('-0.01'), 'must_be_non_negative');
    });
  });

  group('Validators.dueOnOrAfterIssued', () {
    test('null inputs → "required"', () {
      expect(
        Validators.dueOnOrAfterIssued(issued: null, due: DateTime(2026)),
        'required',
      );
      expect(
        Validators.dueOnOrAfterIssued(issued: DateTime(2026), due: null),
        'required',
      );
    });
    test('due before issued → "due_before_issued"', () {
      expect(
        Validators.dueOnOrAfterIssued(
          issued: DateTime(2026, 5, 10),
          due: DateTime(2026, 5, 1),
        ),
        'due_before_issued',
      );
    });
    test('same day is allowed (boundary inclusive)', () {
      final d = DateTime(2026, 5, 10);
      expect(Validators.dueOnOrAfterIssued(issued: d, due: d), isNull);
    });
    test('due after issued → null', () {
      expect(
        Validators.dueOnOrAfterIssued(
          issued: DateTime(2026, 5, 1),
          due: DateTime(2026, 6, 1),
        ),
        isNull,
      );
    });
  });

  group('Validators.email', () {
    test('null / empty / whitespace → "required"', () {
      expect(Validators.email(null), 'required');
      expect(Validators.email(''), 'required');
      expect(Validators.email('   '), 'required');
    });
    test('missing @, missing dot, or whitespace inside → "invalid_email"', () {
      expect(Validators.email('not-an-email'), 'invalid_email');
      expect(Validators.email('foo@bar'), 'invalid_email');
      expect(Validators.email('foo @bar.com'), 'invalid_email');
      expect(Validators.email('foo@bar .com'), 'invalid_email');
    });
    test('plausible address → null', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('first.last+tag@example.com'), isNull);
      expect(Validators.email('  trimmed@me.io  '), isNull);
    });
  });

  group('Validators.compose', () {
    test('returns the FIRST failing rule', () {
      final result = Validators.compose(
        '',
        [Validators.required, Validators.positiveNumber],
      );
      expect(result, 'required');
    });
    test('returns null when every rule passes', () {
      final result = Validators.compose(
        '5',
        [Validators.required, Validators.positiveNumber],
      );
      expect(result, isNull);
    });
  });
}
