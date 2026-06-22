import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/features/auth/entities/permission.dart';
import 'package:erp_mobile/features/auth/permission_gate.dart';
import 'package:erp_mobile/features/finance/data/repositories/invoices_repository.dart';
import 'package:erp_mobile/features/finance/entities/invoice.dart';
import 'package:erp_mobile/features/finance/presentation/bloc/invoice_action_bloc.dart';
import 'package:erp_mobile/features/finance/presentation/bloc/invoice_action_event.dart';
import 'package:erp_mobile/features/finance/presentation/bloc/invoice_action_state.dart';
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
      totalAmount: r'$1.00',
    );

InvoiceActionBloc _makeBloc({
  required _MockRepo repo,
  required _MockPerms perms,
}) {
  return InvoiceActionBloc(
    invoices: repo,
    permissions: perms,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const Permission(token: 'x'));
  });

  late _MockRepo repo;
  late _MockPerms perms;

  setUp(() {
    repo = _MockRepo();
    perms = _MockPerms();
  });

  group('InvoiceActionBloc', () {
    test('initial state is InvoiceActionInitial', () {
      final bloc = _makeBloc(repo: repo, perms: perms);
      expect(bloc.state, isA<InvoiceActionInitial>());
    });

    test('approve: Loading → Success on happy path', () async {
      when(() => perms.currentUserId).thenReturn('u-1');
      when(() => perms.holds(any())).thenReturn(true);
      when(() => repo.findById('inv-1'))
          .thenAnswer((_) async => _inv());
      when(() => repo.approve(
            invoiceId: 'inv-1',
            approverId: 'u-1',
            actionedAt: any(named: 'actionedAt'),
          )).thenAnswer(
        (_) async => _inv(status: InvoiceStatus.approved),
      );

      final bloc = _makeBloc(repo: repo, perms: perms);
      final emitted = <InvoiceActionState>[];
      bloc.stream.listen(emitted.add);

      bloc.add(const InvoiceActionApprove('inv-1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emitted.first, isA<InvoiceActionLoading>());
      expect(emitted.last, isA<InvoiceActionSuccess>());
      expect((emitted.last as InvoiceActionSuccess).invoice.status,
          InvoiceStatus.approved);
    });

    test('approve: no signed-in user → Failure(unauthorized)', () async {
      when(() => perms.currentUserId).thenReturn(null);

      final bloc = _makeBloc(repo: repo, perms: perms);
      final emitted = <InvoiceActionState>[];
      bloc.stream.listen(emitted.add);

      bloc.add(const InvoiceActionApprove('inv-1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emitted.last, isA<InvoiceActionFailure>());
      expect((emitted.last as InvoiceActionFailure).failure,
          isA<UnauthorizedFailure>());
    });

    test('approve: forbidden surfaced as InvoiceActionFailure', () async {
      when(() => perms.currentUserId).thenReturn('u-1');
      when(() => perms.holds(any())).thenReturn(false);

      final bloc = _makeBloc(repo: repo, perms: perms);
      final emitted = <InvoiceActionState>[];
      bloc.stream.listen(emitted.add);

      bloc.add(const InvoiceActionApprove('inv-1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emitted.last, isA<InvoiceActionFailure>());
      expect((emitted.last as InvoiceActionFailure).failure,
          isA<ForbiddenFailure>());
    });

    test('reject: Loading → Success with the trimmed reason', () async {
      when(() => perms.currentUserId).thenReturn('u-1');
      when(() => perms.holds(any())).thenReturn(true);
      when(() => repo.findById('inv-1'))
          .thenAnswer((_) async => _inv());
      when(() => repo.reject(
            invoiceId: 'inv-1',
            approverId: 'u-1',
            reason: 'wrong PO',
            actionedAt: any(named: 'actionedAt'),
          )).thenAnswer(
        (_) async => _inv(status: InvoiceStatus.rejected),
      );

      final bloc = _makeBloc(repo: repo, perms: perms);
      final emitted = <InvoiceActionState>[];
      bloc.stream.listen(emitted.add);

      bloc.add(const InvoiceActionReject(
        invoiceId: 'inv-1',
        reason: '   wrong PO   ',
      ));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emitted.last, isA<InvoiceActionSuccess>());
      expect((emitted.last as InvoiceActionSuccess).invoice.status,
          InvoiceStatus.rejected);
    });

    test('reject: empty reason → ValidationFailure (without hitting repo)',
        () async {
      when(() => perms.currentUserId).thenReturn('u-1');

      final bloc = _makeBloc(repo: repo, perms: perms);
      final emitted = <InvoiceActionState>[];
      bloc.stream.listen(emitted.add);

      bloc.add(const InvoiceActionReject(
        invoiceId: 'inv-1',
        reason: '   ',
      ));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emitted.last, isA<InvoiceActionFailure>());
      expect((emitted.last as InvoiceActionFailure).failure,
          isA<ValidationFailure>());
      verifyNever(() => repo.findById(any()));
    });

    test('submit: draft → pendingApproval', () async {
      when(() => repo.findById('inv-1'))
          .thenAnswer((_) async => _inv(status: InvoiceStatus.draft));
      when(() => repo.submitForApproval(
            invoiceId: 'inv-1',
            actionedAt: any(named: 'actionedAt'),
          )).thenAnswer(
        (_) async => _inv(status: InvoiceStatus.pendingApproval),
      );

      final bloc = _makeBloc(repo: repo, perms: perms);
      final emitted = <InvoiceActionState>[];
      bloc.stream.listen(emitted.add);

      bloc.add(const InvoiceActionSubmit('inv-1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emitted.last, isA<InvoiceActionSuccess>());
      expect((emitted.last as InvoiceActionSuccess).invoice.status,
          InvoiceStatus.pendingApproval);
    });

    test('reopen: rejected → draft', () async {
      when(() => repo.findById('inv-1'))
          .thenAnswer((_) async => _inv(status: InvoiceStatus.rejected));
      when(() => repo.reopen(
            invoiceId: 'inv-1',
            actionedAt: any(named: 'actionedAt'),
          )).thenAnswer(
        (_) async => _inv(status: InvoiceStatus.draft),
      );

      final bloc = _makeBloc(repo: repo, perms: perms);
      final emitted = <InvoiceActionState>[];
      bloc.stream.listen(emitted.add);

      bloc.add(const InvoiceActionReopen('inv-1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(emitted.last, isA<InvoiceActionSuccess>());
      expect((emitted.last as InvoiceActionSuccess).invoice.status,
          InvoiceStatus.draft);
    });
  });
}
