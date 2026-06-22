import 'package:erp_mobile/features/procurement/data/repositories/purchase_requests_repository.dart';
import 'package:erp_mobile/features/procurement/entities/purchase_request.dart';
import 'package:test/test.dart';

PurchaseRequest _pr(PurchaseRequestStatus s) => PurchaseRequest(
      id: '1',
      number: 'PR-2026-001',
      requesterName: 'X',
      costCenter: 'CC-1',
      approverName: 'Y',
      createdAt: DateTime.utc(2026, 5, 1),
      status: s,
      totalAmount: r'$100.00',
      lineItems: const [],
    );

void main() {
  // approve/reject/submit are now instance methods on the repository
  // (Module 4 refactor folded the former `PurchaseRequestApprovalUseCase`
  // onto `PurchaseRequestsRepository`). They're still pure state-machine
  // transitions — no I/O — so we exercise them on a plain instance.
  final repo = PurchaseRequestsRepository();

  group('approve', () {
    test('submitted → approved', () {
      final out = repo.approve(_pr(PurchaseRequestStatus.submitted));
      expect(out.result, PurchaseRequestApprovalResult.ok);
      expect(out.pr.status, PurchaseRequestStatus.approved);
    });

    test('any other status → notAllowed (returns input unchanged)', () {
      for (final s in [
        PurchaseRequestStatus.draft,
        PurchaseRequestStatus.approved,
        PurchaseRequestStatus.rejected,
        PurchaseRequestStatus.converted,
      ]) {
        final input = _pr(s);
        final out = repo.approve(input);
        expect(out.result,
            PurchaseRequestApprovalResult.notAllowedFromCurrentStatus);
        expect(out.pr.status, s);
      }
    });
  });

  group('reject', () {
    test('blank reason → reasonRequired (status unchanged)', () {
      final out =
          repo.reject(_pr(PurchaseRequestStatus.submitted), reason: '   ');
      expect(out.result, PurchaseRequestApprovalResult.reasonRequired);
      expect(out.pr.status, PurchaseRequestStatus.submitted);
    });

    test('submitted + reason → rejected', () {
      final out = repo.reject(_pr(PurchaseRequestStatus.submitted),
          reason: 'over budget');
      expect(out.result, PurchaseRequestApprovalResult.ok);
      expect(out.pr.status, PurchaseRequestStatus.rejected);
    });

    test('cannot reject draft / approved / rejected / converted', () {
      for (final s in [
        PurchaseRequestStatus.draft,
        PurchaseRequestStatus.approved,
        PurchaseRequestStatus.rejected,
        PurchaseRequestStatus.converted,
      ]) {
        final out = repo.reject(_pr(s), reason: 'no');
        expect(out.result,
            PurchaseRequestApprovalResult.notAllowedFromCurrentStatus);
      }
    });
  });

  group('submit (draft → submitted)', () {
    test('draft → submitted', () {
      final out = repo.submit(_pr(PurchaseRequestStatus.draft));
      expect(out.result, PurchaseRequestApprovalResult.ok);
      expect(out.pr.status, PurchaseRequestStatus.submitted);
    });
    test('non-draft → notAllowed', () {
      final out = repo.submit(_pr(PurchaseRequestStatus.submitted));
      expect(out.result,
          PurchaseRequestApprovalResult.notAllowedFromCurrentStatus);
    });
  });
}
