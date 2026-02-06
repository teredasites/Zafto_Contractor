// ZAFTO Invoice Repository
// Created: Sprint B1d (Session 42)
//
// Supabase CRUD for invoices table.
// RLS handles company scoping automatically.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/invoice.dart';

class InvoiceRepository {
  // ============================================================
  // READ
  // ============================================================

  Future<List<Invoice>> getInvoices() async {
    try {
      final response = await supabase
          .from('invoices')
          .select()
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false);
      return (response as List)
          .map((row) => Invoice.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch invoices: $e', cause: e);
    }
  }

  Future<Invoice?> getInvoice(String id) async {
    try {
      final response = await supabase
          .from('invoices')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Invoice.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to fetch invoice: $e', cause: e);
    }
  }

  Future<List<Invoice>> getInvoicesByStatus(InvoiceStatus status) async {
    try {
      final response = await supabase
          .from('invoices')
          .select()
          .eq('status', status.name)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => Invoice.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
          'Failed to fetch invoices by status: $e', cause: e);
    }
  }

  Future<List<Invoice>> getInvoicesByCustomer(String customerId) async {
    try {
      final response = await supabase
          .from('invoices')
          .select()
          .eq('customer_id', customerId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => Invoice.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
          'Failed to fetch invoices for customer: $e', cause: e);
    }
  }

  Future<List<Invoice>> getInvoicesByJob(String jobId) async {
    try {
      final response = await supabase
          .from('invoices')
          .select()
          .eq('job_id', jobId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => Invoice.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
          'Failed to fetch invoices for job: $e', cause: e);
    }
  }

  Future<List<Invoice>> searchInvoices(String query) async {
    try {
      final q = '%$query%';
      final response = await supabase
          .from('invoices')
          .select()
          .or('invoice_number.ilike.$q,customer_name.ilike.$q,notes.ilike.$q')
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false);
      return (response as List)
          .map((row) => Invoice.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to search invoices: $e', cause: e);
    }
  }

  // ============================================================
  // WRITE
  // ============================================================

  Future<Invoice> createInvoice(Invoice invoice) async {
    try {
      final response = await supabase
          .from('invoices')
          .insert(invoice.toInsertJson())
          .select()
          .single();
      return Invoice.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create invoice: $e',
        userMessage: 'Could not create invoice. Please try again.',
        cause: e,
      );
    }
  }

  Future<Invoice> updateInvoice(String id, Invoice invoice) async {
    try {
      final response = await supabase
          .from('invoices')
          .update(invoice.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return Invoice.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update invoice: $e',
        userMessage: 'Could not update invoice. Please try again.',
        cause: e,
      );
    }
  }

  Future<Invoice> updateInvoiceStatus(
      String id, InvoiceStatus status) async {
    try {
      final data = <String, dynamic>{'status': status.name};
      if (status == InvoiceStatus.paid) {
        data['paid_at'] = DateTime.now().toUtc().toIso8601String();
      } else if (status == InvoiceStatus.sent) {
        data['sent_at'] = DateTime.now().toUtc().toIso8601String();
      }
      final response = await supabase
          .from('invoices')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Invoice.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update invoice status: $e',
        userMessage:
            'Could not update invoice status. Please try again.',
        cause: e,
      );
    }
  }

  Future<Invoice> recordPayment(
    String id, {
    required double amount,
    required String method,
    String? reference,
  }) async {
    try {
      final invoice = await getInvoice(id);
      if (invoice == null) {
        throw NotFoundError('Invoice not found');
      }
      final newAmountPaid = invoice.amountPaid + amount;
      final newAmountDue = invoice.total - newAmountPaid;
      final isFullyPaid = newAmountDue <= 0;

      final data = <String, dynamic>{
        'amount_paid': newAmountPaid,
        'amount_due': newAmountDue < 0 ? 0 : newAmountDue,
        'payment_method': method,
        'payment_reference': reference,
        'status': isFullyPaid ? 'paid' : 'partiallyPaid',
      };
      if (isFullyPaid) {
        data['paid_at'] = DateTime.now().toUtc().toIso8601String();
      }

      final response = await supabase
          .from('invoices')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Invoice.fromJson(response);
    } catch (e) {
      if (e is AppError) rethrow;
      throw DatabaseError(
        'Failed to record payment: $e',
        userMessage: 'Could not record payment. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> deleteInvoice(String id) async {
    try {
      await supabase
          .from('invoices')
          .update(
              {'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete invoice: $e',
        userMessage: 'Could not delete invoice. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // SEQUENCE
  // ============================================================

  // Get the next invoice number (INV-YYYY-NNNN format).
  // Reads the current max from the DB so it's multi-device safe.
  Future<String> nextInvoiceNumber() async {
    try {
      final year = DateTime.now().year;
      final prefix = 'INV-$year-';
      final response = await supabase
          .from('invoices')
          .select('invoice_number')
          .like('invoice_number', '$prefix%')
          .order('invoice_number', ascending: false)
          .limit(1)
          .maybeSingle();

      int next = 1;
      if (response != null) {
        final lastNumber = response['invoice_number'] as String;
        final seq = int.tryParse(lastNumber.split('-').last) ?? 0;
        next = seq + 1;
      }
      return '$prefix${next.toString().padLeft(4, '0')}';
    } catch (e) {
      // Fallback: timestamp-based
      final year = DateTime.now().year;
      final ms = DateTime.now().millisecondsSinceEpoch % 10000;
      return 'INV-$year-${ms.toString().padLeft(4, '0')}';
    }
  }
}
