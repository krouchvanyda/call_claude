import 'package:drift/drift.dart';

import 'cached_invoices.dart';

/// Drift table for invoice line items (Slice 3.2.4).
///
/// **Cascade-delete** on the FK so wiping an invoice automatically
/// drops its lines — saves the DAO from doing the bookkeeping in two
/// places.
///
/// **Sort key** is [position] (caller-assigned) rather than insertion
/// order so reordering a draft's lines doesn't require deleting +
/// reinserting the whole list.
@DataClassName('CachedInvoiceLineRow')
class CachedInvoiceLines extends Table {
  TextColumn get id => text()();

  TextColumn get invoiceId =>
      text().references(CachedInvoices, #id, onDelete: KeyAction.cascade)();

  IntColumn get position => integer()();

  TextColumn get description => text()();
  TextColumn get sku => text().nullable()();
  RealColumn get quantity => real()();
  TextColumn get unitPrice => text()();
  TextColumn get lineTotal => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
