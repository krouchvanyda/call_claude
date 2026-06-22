import 'package:bloc/bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../auth/permission_gate.dart';
import '../../data/repositories/invoices_repository.dart';
import 'invoice_action_event.dart';
import 'invoice_action_state.dart';

/// Bloc for invoice approval workflow actions (Slice 3.2.4).
///
/// **Why a single bloc for four events**: approve/reject/submit/reopen
/// share the same `Loading → Success/Failure` shape, and the detail
/// page only needs one of them in flight at a time. Keeping them in
/// one bloc avoids three near-identical class triples.
///
/// **`approverId` is pulled lazily** from [PermissionGate] at
/// event-handle time rather than ctor time so the bloc still works if
/// the snapshot's user changes (e.g. dev impersonation toggle in
/// Storybook). For production this is the signed-in user.
///
/// Flat MVVM: the four workflow operations are free top-level functions
/// living in `invoices_repository.dart` ([`approveInvoice`],
/// [`rejectInvoice`], [`submitInvoiceForApproval`], [`reopenInvoice`])
/// — no more use-case classes to inject.
class InvoiceActionBloc extends Bloc<InvoiceActionEvent, InvoiceActionState> {
  InvoiceActionBloc({
    required InvoicesRepository invoices,
    required PermissionGate permissions,
  })  : _invoices = invoices,
        _permissions = permissions,
        super(const InvoiceActionInitial()) {
    on<InvoiceActionApprove>(_onApprove);
    on<InvoiceActionReject>(_onReject);
    on<InvoiceActionSubmit>(_onSubmit);
    on<InvoiceActionReopen>(_onReopen);
  }

  final InvoicesRepository _invoices;
  final PermissionGate _permissions;

  Future<void> _onApprove(
    InvoiceActionApprove event,
    Emitter<InvoiceActionState> emit,
  ) async {
    emit(const InvoiceActionLoading());
    final approverId = _permissions.currentUserId;
    if (approverId == null) {
      emit(const InvoiceActionFailure(
        Failure.unauthorized(message: 'No signed-in user'),
      ));
      return;
    }
    try {
      final invoice = await approveInvoice(
        invoiceId: event.invoiceId,
        approverId: approverId,
        invoices: _invoices,
        gate: _permissions,
      );
      emit(InvoiceActionSuccess(invoice));
    } on Failure catch (f) {
      emit(InvoiceActionFailure(f));
    } catch (e) {
      emit(InvoiceActionFailure(Failure.unknown(message: e.toString())));
    }
  }

  Future<void> _onReject(
    InvoiceActionReject event,
    Emitter<InvoiceActionState> emit,
  ) async {
    emit(const InvoiceActionLoading());
    final approverId = _permissions.currentUserId;
    if (approverId == null) {
      emit(const InvoiceActionFailure(
        Failure.unauthorized(message: 'No signed-in user'),
      ));
      return;
    }
    try {
      final invoice = await rejectInvoice(
        invoiceId: event.invoiceId,
        approverId: approverId,
        reason: event.reason,
        invoices: _invoices,
        gate: _permissions,
      );
      emit(InvoiceActionSuccess(invoice));
    } on Failure catch (f) {
      emit(InvoiceActionFailure(f));
    } catch (e) {
      emit(InvoiceActionFailure(Failure.unknown(message: e.toString())));
    }
  }

  Future<void> _onSubmit(
    InvoiceActionSubmit event,
    Emitter<InvoiceActionState> emit,
  ) async {
    emit(const InvoiceActionLoading());
    try {
      final invoice = await submitInvoiceForApproval(
        invoiceId: event.invoiceId,
        invoices: _invoices,
      );
      emit(InvoiceActionSuccess(invoice));
    } on Failure catch (f) {
      emit(InvoiceActionFailure(f));
    } catch (e) {
      emit(InvoiceActionFailure(Failure.unknown(message: e.toString())));
    }
  }

  Future<void> _onReopen(
    InvoiceActionReopen event,
    Emitter<InvoiceActionState> emit,
  ) async {
    emit(const InvoiceActionLoading());
    try {
      final invoice = await reopenInvoice(
        invoiceId: event.invoiceId,
        invoices: _invoices,
      );
      emit(InvoiceActionSuccess(invoice));
    } on Failure catch (f) {
      emit(InvoiceActionFailure(f));
    } catch (e) {
      emit(InvoiceActionFailure(Failure.unknown(message: e.toString())));
    }
  }
}
