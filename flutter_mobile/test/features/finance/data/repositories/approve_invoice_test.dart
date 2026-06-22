import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/features/auth/entities/permission.dart';
import 'package:erp_mobile/features/auth/permission_gate.dart';
import 'package:erp_mobile/features/finance/data/repositories/invoices_repository.dart';
import 'package:erp_mobile/features/finance/entities/invoice.dart';
import 'package:erp_mobile/features/finance/entities/invoice_detail.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRepo extends Mock implements InvoicesRepository {}

class _MockPerms extends Mock implements PermissionGate {}

Invoice _inv({
  String id = 'inv-1',
  InvoiceStatus status = InvoiceStatus.pendingApproval,
}) =>
    Invoice(
      id: id,
      invoiceNumber: 'INV-001',
      customerName: 'Acme',
      issuedAt: DateTime.utc(2026, 5, 1),
      dueAt: DateTime.utc(2026, 6, 1),
      status: status,
      totalAmount: r'$100.00',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const Permission(token: 'x'));
  });

  late _MockRepo repo;
  late _MockPerms perms;
  final fixedClock = DateTime.utc(2026, 5, 13, 10, 0);

  setUp(() {
    repo = _MockRepo();
    perms = _MockPerms();
  });

  group('approveInvoice', () {
    test('forbidden when caller lacks finance.approve', () async {
      when(() => perms.holds(any())).thenReturn(false);

      await expectLater(
        approveInvoice(
          invoiceId: 'inv-1',
          approverId: 'u',
          invoices: repo,
          gate: perms,
          clock: () => fixedClock,
        ),
        throwsA(isA<ForbiddenFailure>()),
      );
      // Repo never touched.
      verifyNever(() => repo.findById(any()));
      verifyNever(() => repo.approve(
            invoiceId: any(named: 'invoiceId'),
            approverId: any(named: 'approverId'),
            actionedAt: any(named: 'actionedAt'),
          ));
    });

    test('notFound when the id is unknown', () async {
      when(() => perms.holds(any())).thenReturn(true);
      when(() => repo.findById('missing'))
          .thenAnswer((_) async => null);

      await expectLater(
        approveInvoice(
          invoiceId: 'missing',
          approverId: 'u',
          invoices: repo,
          gate: perms,
          clock: () => fixedClock,
        ),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('conflict when status is not pendingApproval (no double-action)',
        () async {
      when(() => perms.holds(any())).thenReturn(true);

      for (final s in [
        InvoiceStatus.draft,
        InvoiceStatus.approved,
        InvoiceStatus.rejected,
      ]) {
        when(() => repo.findById('inv-1'))
            .thenAnswer((_) async => _inv(status: s));
        await expectLater(
          approveInvoice(
            invoiceId: 'inv-1',
            approverId: 'u',
            invoices: repo,
            gate: perms,
            clock: () => fixedClock,
          ),
          throwsA(isA<ConflictFailure>()),
          reason: 'status $s should refuse approve',
        );
      }
    });

    test('happy path — calls repo.approve with the injected clock', () async {
      when(() => perms.holds(const Permission(
            token: kFinanceApprovePermission,
          ))).thenReturn(true);
      when(() => repo.findById('inv-1'))
          .thenAnswer((_) async => _inv(status: InvoiceStatus.pendingApproval));
      when(() => repo.approve(
            invoiceId: 'inv-1',
            approverId: 'u-42',
            actionedAt: fixedClock,
          )).thenAnswer(
        (_) async => _inv(status: InvoiceStatus.approved),
      );

      final result = await approveInvoice(
        invoiceId: 'inv-1',
        approverId: 'u-42',
        invoices: repo,
        gate: perms,
        clock: () => fixedClock,
      );
      expect(result.status, InvoiceStatus.approved);
      verify(() => repo.approve(
            invoiceId: 'inv-1',
            approverId: 'u-42',
            actionedAt: fixedClock,
          )).called(1);
    });
  });
}

// Required by mocktail when registering fallback for entities used
// inside `any(named: ...)` matchers. The detail entity isn't directly
// matched here but the import path keeps the test self-contained.
// ignore: unused_element
InvoiceDetail _detailFallback() {
  return InvoiceDetail(
    header: _inv(),
    subtotal: r'$0',
    tax: r'$0',
    lineItems: const [],
  );
}
