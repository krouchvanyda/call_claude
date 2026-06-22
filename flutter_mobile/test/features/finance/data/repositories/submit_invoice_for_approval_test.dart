import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/features/finance/data/repositories/invoices_repository.dart';
import 'package:erp_mobile/features/finance/entities/invoice.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockRepo extends Mock implements InvoicesRepository {}

Invoice _inv(InvoiceStatus s) => Invoice(
      id: 'inv-1',
      invoiceNumber: 'INV-001',
      customerName: 'Acme',
      issuedAt: DateTime.utc(2026, 5, 1),
      dueAt: DateTime.utc(2026, 6, 1),
      status: s,
      totalAmount: r'$1.00',
    );

void main() {
  late _MockRepo repo;
  final clock = DateTime.utc(2026, 5, 13);

  setUp(() {
    repo = _MockRepo();
  });

  test('draft → pendingApproval', () async {
    when(() => repo.findById('inv-1'))
        .thenAnswer((_) async => _inv(InvoiceStatus.draft));
    when(() => repo.submitForApproval(
          invoiceId: 'inv-1',
          actionedAt: clock,
        )).thenAnswer(
      (_) async => _inv(InvoiceStatus.pendingApproval),
    );

    final out = await submitInvoiceForApproval(
      invoiceId: 'inv-1',
      invoices: repo,
      clock: () => clock,
    );
    expect(out.status, InvoiceStatus.pendingApproval);
  });

  test('non-draft → ConflictFailure', () async {
    for (final s in [
      InvoiceStatus.pendingApproval,
      InvoiceStatus.approved,
      InvoiceStatus.rejected,
    ]) {
      when(() => repo.findById('inv-1'))
          .thenAnswer((_) async => _inv(s));
      await expectLater(
        submitInvoiceForApproval(
          invoiceId: 'inv-1',
          invoices: repo,
          clock: () => clock,
        ),
        throwsA(isA<ConflictFailure>()),
      );
    }
  });

  test('unknown id → NotFoundFailure', () async {
    when(() => repo.findById('nope')).thenAnswer((_) async => null);
    await expectLater(
      submitInvoiceForApproval(
        invoiceId: 'nope',
        invoices: repo,
        clock: () => clock,
      ),
      throwsA(isA<NotFoundFailure>()),
    );
  });
}
