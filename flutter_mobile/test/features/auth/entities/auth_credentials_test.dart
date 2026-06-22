import 'package:erp_mobile/features/auth/entities/auth_credentials.dart';
import 'package:test/test.dart';

void main() {
  group('AuthCredentials', () {
    test('empty() returns ("", "")', () {
      final empty = AuthCredentials.empty();
      expect(empty.email, '');
      expect(empty.password, '');
    });

    test('two instances with the same fields are equal (freezed)', () {
      const a = AuthCredentials(email: 'a@b.co', password: 'hunter22');
      const b = AuthCredentials(email: 'a@b.co', password: 'hunter22');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('AuthCredentials.isValid', () {
    test('true for plausible email + 8+ char password', () {
      const c = AuthCredentials(email: 'a@b.co', password: 'hunter22');
      expect(c.isValid, isTrue);
    });

    test('email may carry surrounding whitespace and still pass (trimmed)',
        () {
      const c = AuthCredentials(
        email: '  alice@example.com  ',
        password: 'hunter22',
      );
      expect(c.isValid, isTrue);
    });

    test('false on missing @ in email', () {
      const c = AuthCredentials(email: 'noatsign', password: 'hunter22');
      expect(c.isValid, isFalse);
    });

    test('false on missing TLD in email', () {
      const c = AuthCredentials(email: 'alice@hostonly', password: 'hunter22');
      expect(c.isValid, isFalse);
    });

    test('false on whitespace inside email local part', () {
      const c = AuthCredentials(
        email: 'alice space@example.com',
        password: 'hunter22',
      );
      expect(c.isValid, isFalse);
    });

    test('false on password shorter than 8 characters', () {
      const c = AuthCredentials(email: 'a@b.co', password: '1234567');
      expect(c.isValid, isFalse);
    });

    test('false on empty values', () {
      expect(AuthCredentials.empty().isValid, isFalse);
    });
  });

  group('AuthCredentials.validate', () {
    test('returns null on a fully valid pair', () {
      const c = AuthCredentials(email: 'a@b.co', password: 'hunter22');
      expect(c.validate(), isNull);
    });

    test('reports emailMissing on empty email', () {
      const c = AuthCredentials(email: '', password: 'hunter22');
      expect(c.validate(), CredentialIssue.emailMissing);
    });

    test('reports emailMissing on whitespace-only email', () {
      const c = AuthCredentials(email: '   ', password: 'hunter22');
      expect(c.validate(), CredentialIssue.emailMissing);
    });

    test('reports emailMalformed on garbled email', () {
      const c = AuthCredentials(email: 'not-an-email', password: 'hunter22');
      expect(c.validate(), CredentialIssue.emailMalformed);
    });

    test('reports passwordMissing when password is empty', () {
      const c = AuthCredentials(email: 'a@b.co', password: '');
      expect(c.validate(), CredentialIssue.passwordMissing);
    });

    test('reports passwordTooShort when below 8 chars', () {
      const c = AuthCredentials(email: 'a@b.co', password: 'short');
      expect(c.validate(), CredentialIssue.passwordTooShort);
    });

    test('email issues take precedence over password issues', () {
      const c = AuthCredentials(email: '', password: '');
      expect(c.validate(), CredentialIssue.emailMissing);
    });
  });
}
