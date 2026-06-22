import '../../../../core/error/failure.dart';
import '../../entities/invoice.dart';

/// One-state-per-stage shape (Slice 3.2.4 spec):
/// `Initial → Loading → Success | Failure`.
sealed class InvoiceActionState {
  const InvoiceActionState();
}

class InvoiceActionInitial extends InvoiceActionState {
  const InvoiceActionInitial();
}

class InvoiceActionLoading extends InvoiceActionState {
  const InvoiceActionLoading();
}

class InvoiceActionSuccess extends InvoiceActionState {
  const InvoiceActionSuccess(this.invoice);
  final Invoice invoice;
}

class InvoiceActionFailure extends InvoiceActionState {
  const InvoiceActionFailure(this.failure);
  final Failure failure;
}
