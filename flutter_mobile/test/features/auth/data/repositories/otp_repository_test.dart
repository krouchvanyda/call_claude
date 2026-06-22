import 'package:erp_mobile/features/auth/data/repositories/otp_repository.dart';
import 'package:erp_mobile/features/auth/entities/otp_verification_result.dart';
import 'package:test/test.dart';

void main() {
  group('OtpRepository', () {
    const repo = OtpRepository();

    test('accepts the canonical dev code', () async {
      final result = await repo.verify(OtpRepository.devCode);
      expect(result, isA<OtpAccepted>());
    });

    test('rejects any other code as incorrect', () async {
      final result = await repo.verify('000000');
      expect(result, isA<OtpRejected>());
      expect((result as OtpRejected).reason, OtpRejectionReason.incorrect);
    });

    test('rejects partial input as incorrect (length check is caller-side)',
        () async {
      final result = await repo.verify('12345');
      expect((result as OtpRejected).reason, OtpRejectionReason.incorrect);
    });

    test('rejects empty input', () async {
      final result = await repo.verify('');
      expect(result, isA<OtpRejected>());
    });
  });
}
