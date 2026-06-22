import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/features/auth/entities/permission.dart';
import 'package:erp_mobile/features/auth/permission_gate.dart';
import 'package:erp_mobile/features/finance/data/repositories/invoices_repository.dart';
import 'package:erp_mobile/features/finance/entities/invoice.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRepo extends Mock implements InvoicesRepository {}

class _MockPerms extends Mock implements PermissionGate {}

Invoice _inv({InvoiceStatus status = InvoiceStatus.pendingApproval}) => Invoice(
      id: 'inv-1',
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
  final fixedClock = DateTime.utc(2026, 5, 13, 11, 30);

  setUp(() {
    repo = _MockRepo();
    perms = _MockPerms();
  });

  group('rejectInvoice', () {
    test('blank reason → ValidationFailure (BEFORE permission/state checks)',
        () async {
      // Permission stub returns false — proves we shortcircuit on the
      // reason check rather than even consulting the permission gate.
      when(() => perms.holds(any())).thenReturn(false);

      await expectLater(
        rejectInvoice(
          invoiceId: 'inv-1',
          approverId: 'u',
          reason: '  ',
          invoices: repo,
          gate: perms,
          clock: () => fixedClock,
        ),
        throwsA(isA<ValidationFailure>()),
      );
      verifyNever(() => perms.holds(any()));
      verifyNever(() => repo.findById(any()));
    });

    test('forbidden when caller lacks finance.approve', () async {
      when(() => perms.holds(any())).thenReturn(false);

      await expectLater(
        rejectInvoice(
          invoiceId: 'inv-1',
          approverId: 'u',
          reason: 'no',
          invoices: repo,
          gate: perms,
          clock: () => fixedClock,
        ),
        throwsA(isA<ForbiddenFailure>()),
      );
    });

    test('notFound when id is unknown', () async {
      when(() => perms.holds(any())).thenReturn(true);
      when(() => repo.findById(any())).thenAnswer((_) async => null);

      await expectLater(
        rejectInvoice(
          invoiceId: 'gone',
          approverId: 'u',
          reason: 'no',
          invoices: repo,
          gate: perms,
          clock: () => fixedClock,
        ),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('conflict for any non-pendingApproval status', () async {
      when(() => perms.holds(any())).thenReturn(true);
      for (final s in [
        InvoiceStatus.draft,
        InvoiceStatus.approved,
        InvoiceStatus.rejected,
      ]) {
        when(() => repo.findById('inv-1'))
            .thenAnswer((_) async => _inv(status: s));
        await expectLater(
          rejectInvoice(
            invoiceId: 'inv-1',
            approverId: 'u',
            reason: 'no',
            invoices: repo,
            gate: perms,
            clock: () => fixedClock,
          ),
          throwsA(isA<ConflictFailure>()),
          reason: 'status $s should refuse reject',
        );
      }
    });

    test('happy path — passes trimmed reason + injected clock to repo',
        () async {
      when(() => perms.holds(any())).thenReturn(true);
      when(() => repo.findById('inv-1'))
          .thenAnswer((_) async => _inv());
      when(() => repo.reject(
            invoiceId: 'inv-1',
            approverId: 'u-99',
            reason: 'over budget',
            actionedAt: fixedClock,
          )).thenAnswer(
        (_) async => _inv(status: InvoiceStatus.rejected),
      );

      final result = await rejectInvoice(
        invoiceId: 'inv-1',
        approverId: 'u-99',
        reason: '  over budget  ',
        invoices: repo,
        gate: perms,
        clock: () => fixedClock,
      );
      expect(result.status, InvoiceStatus.rejected);
      verify(() => repo.reject(
            invoiceId: 'inv-1',
            approverId: 'u-99',
            reason: 'over budget',
            actionedAt: fixedClock,
          )).called(1);
    });
  });
}
