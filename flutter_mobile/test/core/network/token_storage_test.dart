import 'package:erp_mobile/core/network/auth_tokens.dart';
import 'package:erp_mobile/core/network/token_storage.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryTokenStorage', () {
    late TokenStorage storage;

    setUp(() => storage = InMemoryTokenStorage());

    test('starts empty', () async {
      expect(await storage.read(), isNull);
    });

    test('round-trips a token pair', () async {
      const tokens = AuthTokens(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
      );
      await storage.write(tokens);
      expect(await storage.read(), tokens);
    });

    test('overwrites prior tokens on subsequent write', () async {
      await storage.write(const AuthTokens(
        accessToken: 'a1',
        refreshToken: 'r1',
      ));
      await storage.write(const AuthTokens(
        accessToken: 'a2',
        refreshToken: 'r2',
      ));
      final read = await storage.read();
      expect(read?.accessToken, 'a2');
      expect(read?.refreshToken, 'r2');
    });

    test('clear() empties the store', () async {
      await storage.write(const AuthTokens(
        accessToken: 'a',
        refreshToken: 'r',
      ));
      await storage.clear();
      expect(await storage.read(), isNull);
    });
  });
}
