/// Inputs to [InvoiceActionBloc] (Slice 3.2.4).
sealed class InvoiceActionEvent {
  const InvoiceActionEvent();
}

class InvoiceActionApprove extends InvoiceActionEvent {
  const InvoiceActionApprove(this.invoiceId);
  final String invoiceId;
}

class InvoiceActionReject extends InvoiceActionEvent {
  const InvoiceActionReject({
    required this.invoiceId,
    required this.reason,
  });
  final String invoiceId;
  final String reason;
}

class InvoiceActionSubmit extends InvoiceActionEvent {
  const InvoiceActionSubmit(this.invoiceId);
  final String invoiceId;
}

class InvoiceActionReopen extends InvoiceActionEvent {
  const InvoiceActionReopen(this.invoiceId);
  final String invoiceId;
}
