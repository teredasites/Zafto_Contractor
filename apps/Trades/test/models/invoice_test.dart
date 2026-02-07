// ZAFTO Invoice Model Tests
// Tests fromJson (snake_case + camelCase), toJson roundtrip, toInsertJson,
// toUpdateJson, InvoiceLineItem, recalculate(), computed properties,
// factory constructors (fromJob, create).

import 'package:flutter_test/flutter_test.dart';
import 'package:zafto/models/invoice.dart';

void main() {
  // Fixed timestamps.
  final created = DateTime.utc(2025, 6, 15, 10, 0, 0);
  final updated = DateTime.utc(2025, 6, 20, 14, 30, 0);
  final dueDate = DateTime.utc(2025, 7, 15, 0, 0, 0);
  final sentAt = DateTime.utc(2025, 6, 16, 9, 0, 0);
  final viewedAt = DateTime.utc(2025, 6, 17, 11, 0, 0);
  final paidAt = DateTime.utc(2025, 6, 18, 15, 0, 0);
  final approvedAt = DateTime.utc(2025, 6, 15, 12, 0, 0);
  final signedAt = DateTime.utc(2025, 6, 18, 15, 5, 0);

  /// Sample line items as JSONB list.
  List<Map<String, dynamic>> sampleLineItems() => [
        {
          'id': 'item-001',
          'description': 'Panel upgrade labor',
          'quantity': 4.0,
          'unit': 'hour',
          'unitPrice': 125.0,
          'total': 500.0,
          'isTaxable': true,
        },
        {
          'id': 'item-002',
          'description': '200A panel',
          'quantity': 1.0,
          'unit': 'each',
          'unitPrice': 350.0,
          'total': 350.0,
          'isTaxable': true,
        },
        {
          'id': 'item-003',
          'description': 'Permit fee',
          'quantity': 1.0,
          'unit': 'each',
          'unitPrice': 75.0,
          'total': 75.0,
          'isTaxable': false,
        },
      ];

  /// Full snake_case JSON as Supabase would return it.
  Map<String, dynamic> fullSnakeCaseJson() => {
        'id': 'inv-001',
        'company_id': 'comp-001',
        'created_by_user_id': 'user-001',
        'job_id': 'job-001',
        'customer_id': 'cust-001',
        'invoice_number': 'INV-2025-001',
        'customer_name': 'John Smith',
        'customer_email': 'john@example.com',
        'customer_phone': '555-1234',
        'customer_address': '123 Main St, Austin, TX 78701',
        'line_items': sampleLineItems(),
        'subtotal': 925.0,
        'discount_amount': 50.0,
        'discount_reason': 'Repeat customer',
        'tax_rate': 8.25,
        'tax_amount': 70.13,
        'total': 945.13,
        'amount_paid': 200.0,
        'amount_due': 745.13,
        'status': 'sent',
        'requires_approval': true,
        'approved_by_user_id': 'admin-001',
        'approved_at': approvedAt.toIso8601String(),
        'rejection_reason': null,
        'sent_at': sentAt.toIso8601String(),
        'sent_via': 'email',
        'viewed_at': viewedAt.toIso8601String(),
        'paid_at': paidAt.toIso8601String(),
        'payment_method': 'card',
        'payment_reference': 'ch_123abc',
        'signature_data': 'base64sig',
        'signed_by_name': 'John Smith',
        'signed_at': signedAt.toIso8601String(),
        'pdf_path': 'invoices/inv-001.pdf',
        'pdf_url': 'https://storage.example.com/invoices/inv-001.pdf',
        'due_date': dueDate.toIso8601String(),
        'notes': 'Thank you for your business',
        'terms': 'Net 30',
        'created_at': created.toIso8601String(),
        'updated_at': updated.toIso8601String(),
      };

  /// Full camelCase JSON as legacy Firestore would return it.
  Map<String, dynamic> fullCamelCaseJson() => {
        'id': 'inv-001',
        'companyId': 'comp-001',
        'createdByUserId': 'user-001',
        'jobId': 'job-001',
        'customerId': 'cust-001',
        'invoiceNumber': 'INV-2025-001',
        'customerName': 'John Smith',
        'customerEmail': 'john@example.com',
        'customerPhone': '555-1234',
        'customerAddress': '123 Main St, Austin, TX 78701',
        'lineItems': sampleLineItems(),
        'subtotal': 925.0,
        'discountAmount': 50.0,
        'discountReason': 'Repeat customer',
        'taxRate': 8.25,
        'taxAmount': 70.13,
        'total': 945.13,
        'amountPaid': 200.0,
        'amountDue': 745.13,
        'status': 'sent',
        'requiresApproval': true,
        'approvedByUserId': 'admin-001',
        'approvedAt': approvedAt.toIso8601String(),
        'sentAt': sentAt.toIso8601String(),
        'sentVia': 'email',
        'viewedAt': viewedAt.toIso8601String(),
        'paidAt': paidAt.toIso8601String(),
        'paymentMethod': 'card',
        'paymentReference': 'ch_123abc',
        'signatureData': 'base64sig',
        'signedByName': 'John Smith',
        'signedAt': signedAt.toIso8601String(),
        'pdfPath': 'invoices/inv-001.pdf',
        'pdfUrl': 'https://storage.example.com/invoices/inv-001.pdf',
        'dueDate': dueDate.toIso8601String(),
        'notes': 'Thank you for your business',
        'terms': 'Net 30',
        'createdAt': created.toIso8601String(),
        'updatedAt': updated.toIso8601String(),
      };

  group('InvoiceLineItem', () {
    group('fromJson / toJson', () {
      test('parses from JSON correctly', () {
        final item = InvoiceLineItem.fromJson({
          'id': 'item-001',
          'description': 'Labor',
          'quantity': 2.0,
          'unit': 'hour',
          'unitPrice': 100.0,
          'total': 200.0,
          'isTaxable': true,
        });

        expect(item.id, 'item-001');
        expect(item.description, 'Labor');
        expect(item.quantity, 2.0);
        expect(item.unit, 'hour');
        expect(item.unitPrice, 100.0);
        expect(item.total, 200.0);
        expect(item.isTaxable, isTrue);
      });

      test('roundtrips correctly', () {
        final original = InvoiceLineItem.fromJson({
          'id': 'item-001',
          'description': 'Cable',
          'quantity': 3.0,
          'unit': 'roll',
          'unitPrice': 45.50,
          'total': 136.50,
          'isTaxable': false,
        });

        final json = original.toJson();
        final restored = InvoiceLineItem.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.description, original.description);
        expect(restored.quantity, original.quantity);
        expect(restored.unit, original.unit);
        expect(restored.unitPrice, original.unitPrice);
        expect(restored.total, original.total);
        expect(restored.isTaxable, original.isTaxable);
      });

      test('defaults when fields are missing', () {
        final item = InvoiceLineItem.fromJson({
          'id': 'item-001',
          'description': 'Misc',
        });

        expect(item.quantity, 1.0);
        expect(item.unit, 'each');
        expect(item.unitPrice, 0.0);
        expect(item.isTaxable, isTrue);
      });
    });

    group('computed total', () {
      test('calculates total from quantity * unitPrice when total is null', () {
        const item = InvoiceLineItem(
          id: 'item-001',
          description: 'Wire',
          quantity: 5.0,
          unitPrice: 20.0,
        );
        expect(item.total, 100.0);
      });

      test('uses provided total when explicitly set', () {
        const item = InvoiceLineItem(
          id: 'item-001',
          description: 'Wire',
          quantity: 5.0,
          unitPrice: 20.0,
          total: 90.0, // discounted
        );
        expect(item.total, 90.0);
      });
    });

    group('recalculate', () {
      test('recomputes total from quantity * unitPrice', () {
        const item = InvoiceLineItem(
          id: 'item-001',
          description: 'Wire',
          quantity: 5.0,
          unitPrice: 20.0,
          total: 90.0, // stale value
        );
        final recalculated = item.recalculate();
        expect(recalculated.total, 100.0);
      });
    });

    group('copyWith', () {
      test('changes one field while preserving others', () {
        const original = InvoiceLineItem(
          id: 'item-001',
          description: 'Wire',
          quantity: 5.0,
          unitPrice: 20.0,
          isTaxable: true,
        );
        final modified = original.copyWith(quantity: 10.0);

        expect(modified.quantity, 10.0);
        expect(modified.id, 'item-001');
        expect(modified.description, 'Wire');
        expect(modified.unitPrice, 20.0);
        expect(modified.isTaxable, isTrue);
      });
    });
  });

  group('Invoice', () {
    // ================================================================
    // fromJson
    // ================================================================
    group('fromJson', () {
      test('parses snake_case Supabase data with all fields including line items', () {
        final invoice = Invoice.fromJson(fullSnakeCaseJson());

        expect(invoice.id, 'inv-001');
        expect(invoice.companyId, 'comp-001');
        expect(invoice.createdByUserId, 'user-001');
        expect(invoice.jobId, 'job-001');
        expect(invoice.customerId, 'cust-001');
        expect(invoice.invoiceNumber, 'INV-2025-001');
        expect(invoice.customerName, 'John Smith');
        expect(invoice.customerEmail, 'john@example.com');
        expect(invoice.customerPhone, '555-1234');
        expect(invoice.customerAddress, '123 Main St, Austin, TX 78701');
        expect(invoice.lineItems, hasLength(3));
        expect(invoice.lineItems[0].description, 'Panel upgrade labor');
        expect(invoice.lineItems[1].quantity, 1.0);
        expect(invoice.lineItems[2].isTaxable, isFalse);
        expect(invoice.subtotal, 925.0);
        expect(invoice.discountAmount, 50.0);
        expect(invoice.discountReason, 'Repeat customer');
        expect(invoice.taxRate, 8.25);
        expect(invoice.taxAmount, 70.13);
        expect(invoice.total, 945.13);
        expect(invoice.amountPaid, 200.0);
        expect(invoice.amountDue, 745.13);
        expect(invoice.status, InvoiceStatus.sent);
        expect(invoice.requiresApproval, isTrue);
        expect(invoice.approvedByUserId, 'admin-001');
        expect(invoice.approvedAt, approvedAt);
        expect(invoice.sentAt, sentAt);
        expect(invoice.sentVia, 'email');
        expect(invoice.viewedAt, viewedAt);
        expect(invoice.paidAt, paidAt);
        expect(invoice.paymentMethod, 'card');
        expect(invoice.paymentReference, 'ch_123abc');
        expect(invoice.signatureData, 'base64sig');
        expect(invoice.signedByName, 'John Smith');
        expect(invoice.signedAt, signedAt);
        expect(invoice.pdfPath, 'invoices/inv-001.pdf');
        expect(invoice.pdfUrl, 'https://storage.example.com/invoices/inv-001.pdf');
        expect(invoice.dueDate, dueDate);
        expect(invoice.notes, 'Thank you for your business');
        expect(invoice.terms, 'Net 30');
        expect(invoice.createdAt, created);
        expect(invoice.updatedAt, updated);
      });

      test('parses camelCase legacy data', () {
        final invoice = Invoice.fromJson(fullCamelCaseJson());

        expect(invoice.id, 'inv-001');
        expect(invoice.companyId, 'comp-001');
        expect(invoice.invoiceNumber, 'INV-2025-001');
        expect(invoice.lineItems, hasLength(3));
        expect(invoice.discountAmount, 50.0);
        expect(invoice.taxRate, 8.25);
        expect(invoice.amountPaid, 200.0);
        expect(invoice.amountDue, 745.13);
        expect(invoice.requiresApproval, isTrue);
        expect(invoice.approvedByUserId, 'admin-001');
        expect(invoice.paymentMethod, 'card');
        expect(invoice.signatureData, 'base64sig');
        expect(invoice.pdfPath, 'invoices/inv-001.pdf');
        expect(invoice.dueDate, dueDate);
      });

      test('parses with no line items', () {
        final invoice = Invoice.fromJson({
          'id': 'inv-002',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(invoice.lineItems, isEmpty);
      });

      test('parses null line_items as empty list', () {
        final invoice = Invoice.fromJson({
          'line_items': null,
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(invoice.lineItems, isEmpty);
      });

      test('defaults status to draft for unknown value', () {
        final invoice = Invoice.fromJson({
          'status': 'nonexistent',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(invoice.status, InvoiceStatus.draft);
      });
    });

    // ================================================================
    // toJson -> fromJson roundtrip
    // ================================================================
    group('toJson -> fromJson roundtrip', () {
      test('roundtrips all fields correctly including nested line items', () {
        final original = Invoice.fromJson(fullSnakeCaseJson());
        final json = original.toJson();
        final restored = Invoice.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.companyId, original.companyId);
        expect(restored.invoiceNumber, original.invoiceNumber);
        expect(restored.customerName, original.customerName);
        expect(restored.lineItems.length, original.lineItems.length);
        for (int i = 0; i < original.lineItems.length; i++) {
          expect(restored.lineItems[i].id, original.lineItems[i].id);
          expect(restored.lineItems[i].description,
              original.lineItems[i].description);
          expect(
              restored.lineItems[i].quantity, original.lineItems[i].quantity);
          expect(
              restored.lineItems[i].unitPrice, original.lineItems[i].unitPrice);
          expect(restored.lineItems[i].total, original.lineItems[i].total);
          expect(restored.lineItems[i].isTaxable,
              original.lineItems[i].isTaxable);
        }
        expect(restored.subtotal, original.subtotal);
        expect(restored.discountAmount, original.discountAmount);
        expect(restored.taxRate, original.taxRate);
        expect(restored.taxAmount, original.taxAmount);
        expect(restored.total, original.total);
        expect(restored.amountPaid, original.amountPaid);
        expect(restored.amountDue, original.amountDue);
        expect(restored.status, original.status);
        expect(restored.requiresApproval, original.requiresApproval);
        expect(restored.dueDate, original.dueDate);
        expect(restored.createdAt, original.createdAt);
      });
    });

    // ================================================================
    // toInsertJson
    // ================================================================
    group('toInsertJson', () {
      test('outputs snake_case keys', () {
        final invoice = Invoice.fromJson(fullSnakeCaseJson());
        final insertJson = invoice.toInsertJson();

        expect(insertJson.containsKey('company_id'), isTrue);
        expect(insertJson.containsKey('created_by_user_id'), isTrue);
        expect(insertJson.containsKey('job_id'), isTrue);
        expect(insertJson.containsKey('customer_id'), isTrue);
        expect(insertJson.containsKey('invoice_number'), isTrue);
        expect(insertJson.containsKey('customer_name'), isTrue);
        expect(insertJson.containsKey('customer_email'), isTrue);
        expect(insertJson.containsKey('customer_phone'), isTrue);
        expect(insertJson.containsKey('customer_address'), isTrue);
        expect(insertJson.containsKey('line_items'), isTrue);
        expect(insertJson.containsKey('discount_amount'), isTrue);
        expect(insertJson.containsKey('discount_reason'), isTrue);
        expect(insertJson.containsKey('tax_rate'), isTrue);
        expect(insertJson.containsKey('tax_amount'), isTrue);
        expect(insertJson.containsKey('amount_paid'), isTrue);
        expect(insertJson.containsKey('amount_due'), isTrue);
        expect(insertJson.containsKey('requires_approval'), isTrue);
        expect(insertJson.containsKey('due_date'), isTrue);
      });

      test('excludes id, created_at, updated_at', () {
        final invoice = Invoice.fromJson(fullSnakeCaseJson());
        final insertJson = invoice.toInsertJson();

        expect(insertJson.containsKey('id'), isFalse);
        expect(insertJson.containsKey('created_at'), isFalse);
        expect(insertJson.containsKey('updated_at'), isFalse);
        expect(insertJson.containsKey('deleted_at'), isFalse);
      });

      test('excludes workflow fields from insert', () {
        final invoice = Invoice.fromJson(fullSnakeCaseJson());
        final insertJson = invoice.toInsertJson();

        expect(insertJson.containsKey('approved_by_user_id'), isFalse);
        expect(insertJson.containsKey('approved_at'), isFalse);
        expect(insertJson.containsKey('rejection_reason'), isFalse);
        expect(insertJson.containsKey('sent_at'), isFalse);
        expect(insertJson.containsKey('sent_via'), isFalse);
        expect(insertJson.containsKey('viewed_at'), isFalse);
        expect(insertJson.containsKey('paid_at'), isFalse);
        expect(insertJson.containsKey('payment_method'), isFalse);
        expect(insertJson.containsKey('payment_reference'), isFalse);
        expect(insertJson.containsKey('signature_data'), isFalse);
        expect(insertJson.containsKey('signed_by_name'), isFalse);
        expect(insertJson.containsKey('signed_at'), isFalse);
        expect(insertJson.containsKey('pdf_path'), isFalse);
        expect(insertJson.containsKey('pdf_url'), isFalse);
      });

      test('serializes line_items as list of maps', () {
        final invoice = Invoice.fromJson(fullSnakeCaseJson());
        final insertJson = invoice.toInsertJson();

        final items = insertJson['line_items'] as List;
        expect(items, hasLength(3));
        expect((items[0] as Map)['description'], 'Panel upgrade labor');
      });
    });

    // ================================================================
    // recalculate
    // ================================================================
    group('recalculate', () {
      test('recomputes subtotal, taxAmount, total, amountDue from line items', () {
        final invoice = Invoice(
          lineItems: const [
            InvoiceLineItem(
              id: '1',
              description: 'Labor',
              quantity: 2,
              unitPrice: 100,
              isTaxable: true,
            ),
            InvoiceLineItem(
              id: '2',
              description: 'Parts',
              quantity: 1,
              unitPrice: 50,
              isTaxable: true,
            ),
          ],
          taxRate: 10.0,
          discountAmount: 0,
          amountPaid: 0,
          createdAt: created,
          updatedAt: updated,
        );

        final result = invoice.recalculate();

        // subtotal = (2*100) + (1*50) = 250
        expect(result.subtotal, 250.0);
        // taxAmount = 250 * 10/100 = 25
        expect(result.taxAmount, 25.0);
        // total = 250 - 0 + 25 = 275
        expect(result.total, 275.0);
        // amountDue = 275 - 0 = 275
        expect(result.amountDue, 275.0);
      });

      test('handles taxable and non-taxable items correctly', () {
        final invoice = Invoice(
          lineItems: const [
            InvoiceLineItem(
              id: '1',
              description: 'Labor',
              quantity: 1,
              unitPrice: 200,
              isTaxable: true,
            ),
            InvoiceLineItem(
              id: '2',
              description: 'Permit fee',
              quantity: 1,
              unitPrice: 100,
              isTaxable: false,
            ),
          ],
          taxRate: 10.0,
          discountAmount: 0,
          amountPaid: 50,
          createdAt: created,
          updatedAt: updated,
        );

        final result = invoice.recalculate();

        // subtotal = 200 + 100 = 300
        expect(result.subtotal, 300.0);
        // taxAmount = only taxable (200) * 10/100 = 20
        expect(result.taxAmount, 20.0);
        // total = 300 - 0 + 20 = 320
        expect(result.total, 320.0);
        // amountDue = 320 - 50 = 270
        expect(result.amountDue, 270.0);
      });

      test('applies discount correctly', () {
        final invoice = Invoice(
          lineItems: const [
            InvoiceLineItem(
              id: '1',
              description: 'Service',
              quantity: 1,
              unitPrice: 500,
              isTaxable: true,
            ),
          ],
          taxRate: 8.0,
          discountAmount: 50.0,
          amountPaid: 0,
          createdAt: created,
          updatedAt: updated,
        );

        final result = invoice.recalculate();

        // subtotal = 500
        expect(result.subtotal, 500.0);
        // taxAmount = 500 * 8/100 = 40
        expect(result.taxAmount, 40.0);
        // total = 500 - 50 + 40 = 490
        expect(result.total, 490.0);
        // amountDue = 490 - 0 = 490
        expect(result.amountDue, 490.0);
      });

      test('handles empty line items', () {
        final invoice = Invoice(
          lineItems: const [],
          taxRate: 10.0,
          discountAmount: 0,
          amountPaid: 0,
          createdAt: created,
          updatedAt: updated,
        );

        final result = invoice.recalculate();

        expect(result.subtotal, 0.0);
        expect(result.taxAmount, 0.0);
        expect(result.total, 0.0);
        expect(result.amountDue, 0.0);
      });
    });

    // ================================================================
    // Computed properties
    // ================================================================
    group('computed properties', () {
      group('statusLabel', () {
        test('returns correct labels for all 10 statuses', () {
          final statusLabels = {
            InvoiceStatus.draft: 'Draft',
            InvoiceStatus.pendingApproval: 'Pending Approval',
            InvoiceStatus.approved: 'Approved',
            InvoiceStatus.rejected: 'Rejected',
            InvoiceStatus.sent: 'Sent',
            InvoiceStatus.viewed: 'Viewed',
            InvoiceStatus.partiallyPaid: 'Partially Paid',
            InvoiceStatus.paid: 'Paid',
            InvoiceStatus.voided: 'Voided',
            InvoiceStatus.overdue: 'Overdue',
          };

          for (final entry in statusLabels.entries) {
            final invoice = Invoice.fromJson({
              'status': entry.key.name,
              'created_at': created.toIso8601String(),
              'updated_at': updated.toIso8601String(),
            });
            expect(invoice.statusLabel, entry.value,
                reason: 'Status ${entry.key.name} should label as ${entry.value}');
          }
        });

        test('statusDisplay is an alias for statusLabel', () {
          final invoice = Invoice.fromJson({
            'status': 'sent',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.statusDisplay, invoice.statusLabel);
        });
      });

      group('isPaid', () {
        test('returns true for paid status', () {
          final invoice = Invoice.fromJson({
            'status': 'paid',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.isPaid, isTrue);
        });

        test('returns true for partiallyPaid status', () {
          final invoice = Invoice.fromJson({
            'status': 'partiallyPaid',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.isPaid, isTrue);
        });

        test('returns false for other statuses', () {
          for (final status in [
            InvoiceStatus.draft,
            InvoiceStatus.pendingApproval,
            InvoiceStatus.approved,
            InvoiceStatus.rejected,
            InvoiceStatus.sent,
            InvoiceStatus.viewed,
            InvoiceStatus.voided,
            InvoiceStatus.overdue,
          ]) {
            final invoice = Invoice.fromJson({
              'status': status.name,
              'created_at': created.toIso8601String(),
              'updated_at': updated.toIso8601String(),
            });
            expect(invoice.isPaid, isFalse,
                reason: '${status.name} should not be isPaid');
          }
        });
      });

      group('isOverdue', () {
        test('returns true when past dueDate and not paid', () {
          final pastDue = DateTime.now().subtract(const Duration(days: 5));
          final invoice = Invoice.fromJson({
            'status': 'sent',
            'due_date': pastDue.toIso8601String(),
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.isOverdue, isTrue);
        });

        test('returns false when dueDate is in the future', () {
          final futureDue = DateTime.now().add(const Duration(days: 30));
          final invoice = Invoice.fromJson({
            'status': 'sent',
            'due_date': futureDue.toIso8601String(),
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.isOverdue, isFalse);
        });

        test('returns false when status is paid even if past due', () {
          final pastDue = DateTime.now().subtract(const Duration(days: 5));
          final invoice = Invoice.fromJson({
            'status': 'paid',
            'due_date': pastDue.toIso8601String(),
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.isOverdue, isFalse);
        });

        test('returns false when dueDate is null', () {
          final invoice = Invoice.fromJson({
            'status': 'sent',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.isOverdue, isFalse);
        });
      });

      group('isEditable', () {
        test('returns true for draft', () {
          final invoice = Invoice.fromJson({
            'status': 'draft',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.isEditable, isTrue);
        });

        test('returns true for rejected', () {
          final invoice = Invoice.fromJson({
            'status': 'rejected',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.isEditable, isTrue);
        });

        test('returns false for all other statuses', () {
          for (final status in [
            InvoiceStatus.pendingApproval,
            InvoiceStatus.approved,
            InvoiceStatus.sent,
            InvoiceStatus.viewed,
            InvoiceStatus.partiallyPaid,
            InvoiceStatus.paid,
            InvoiceStatus.voided,
            InvoiceStatus.overdue,
          ]) {
            final invoice = Invoice.fromJson({
              'status': status.name,
              'created_at': created.toIso8601String(),
              'updated_at': updated.toIso8601String(),
            });
            expect(invoice.isEditable, isFalse,
                reason: '${status.name} should not be editable');
          }
        });
      });

      group('canSend', () {
        test('returns true for approved status', () {
          final invoice = Invoice.fromJson({
            'status': 'approved',
            'requires_approval': true,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.canSend, isTrue);
        });

        test('returns true for draft when requiresApproval is false', () {
          final invoice = Invoice.fromJson({
            'status': 'draft',
            'requires_approval': false,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.canSend, isTrue);
        });

        test('returns false for draft when requiresApproval is true', () {
          final invoice = Invoice.fromJson({
            'status': 'draft',
            'requires_approval': true,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.canSend, isFalse);
        });

        test('returns false for sent status', () {
          final invoice = Invoice.fromJson({
            'status': 'sent',
            'requires_approval': false,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.canSend, isFalse);
        });
      });

      group('hasSigned', () {
        test('returns true when both signatureData and signedByName are set', () {
          final invoice = Invoice.fromJson({
            'signature_data': 'base64sig',
            'signed_by_name': 'John',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.hasSigned, isTrue);
        });

        test('returns false when signatureData is null', () {
          final invoice = Invoice.fromJson({
            'signed_by_name': 'John',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.hasSigned, isFalse);
        });

        test('returns false when signedByName is null', () {
          final invoice = Invoice.fromJson({
            'signature_data': 'base64sig',
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.hasSigned, isFalse);
        });
      });

      group('display helpers', () {
        test('amountDueDisplay formats currency', () {
          final invoice = Invoice.fromJson({
            'amount_due': 745.13,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.amountDueDisplay, '\$745.13');
        });

        test('totalDisplay formats currency', () {
          final invoice = Invoice.fromJson({
            'total': 1250.00,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.totalDisplay, '\$1250.00');
        });

        test('balanceDue is alias for amountDue', () {
          final invoice = Invoice.fromJson({
            'amount_due': 500.0,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.balanceDue, invoice.amountDue);
        });
      });
    });

    // ================================================================
    // InvoiceStatus enum parsing
    // ================================================================
    group('InvoiceStatus enum', () {
      test('parses all 10 valid status names', () {
        for (final status in InvoiceStatus.values) {
          final invoice = Invoice.fromJson({
            'status': status.name,
            'created_at': created.toIso8601String(),
            'updated_at': updated.toIso8601String(),
          });
          expect(invoice.status, status);
        }
      });

      test('falls back to draft for unknown status', () {
        final invoice = Invoice.fromJson({
          'status': 'nonexistent',
          'created_at': created.toIso8601String(),
          'updated_at': updated.toIso8601String(),
        });
        expect(invoice.status, InvoiceStatus.draft);
      });
    });

    // ================================================================
    // Factory: Invoice.fromJob
    // ================================================================
    group('Invoice.fromJob', () {
      test('sets defaults correctly', () {
        final beforeCreate = DateTime.now();
        final invoice = Invoice.fromJob(
          companyId: 'comp-001',
          createdByUserId: 'user-001',
          invoiceNumber: 'INV-2025-001',
          jobId: 'job-001',
          customerName: 'John Smith',
          customerAddress: '123 Main St',
          customerId: 'cust-001',
          customerEmail: 'john@example.com',
          customerPhone: '555-1234',
          taxRate: 8.25,
        );
        final afterCreate = DateTime.now();

        expect(invoice.companyId, 'comp-001');
        expect(invoice.createdByUserId, 'user-001');
        expect(invoice.invoiceNumber, 'INV-2025-001');
        expect(invoice.jobId, 'job-001');
        expect(invoice.customerName, 'John Smith');
        expect(invoice.customerAddress, '123 Main St');
        expect(invoice.customerId, 'cust-001');
        expect(invoice.customerEmail, 'john@example.com');
        expect(invoice.customerPhone, '555-1234');
        expect(invoice.taxRate, 8.25);
        expect(invoice.status, InvoiceStatus.draft);
        expect(invoice.lineItems, isEmpty);
        expect(invoice.subtotal, 0);
        expect(invoice.total, 0);
        expect(invoice.amountPaid, 0);
        expect(invoice.amountDue, 0);
        expect(invoice.id, '');

        // dueDate should be ~30 days from now
        expect(invoice.dueDate, isNotNull);
        final expectedDue = invoice.createdAt.add(const Duration(days: 30));
        expect(invoice.dueDate!.difference(expectedDue).inSeconds.abs(),
            lessThan(2));

        // createdAt should be between beforeCreate and afterCreate
        expect(
            invoice.createdAt.isAfter(
                beforeCreate.subtract(const Duration(milliseconds: 100))),
            isTrue);
        expect(
            invoice.createdAt
                .isBefore(afterCreate.add(const Duration(milliseconds: 100))),
            isTrue);
      });

      test('uses default taxRate of 0 when not provided', () {
        final invoice = Invoice.fromJob(
          companyId: 'comp-001',
          createdByUserId: 'user-001',
          invoiceNumber: 'INV-001',
          jobId: 'job-001',
          customerName: 'Test',
          customerAddress: '123 St',
        );
        expect(invoice.taxRate, 0);
      });
    });

    // ================================================================
    // Factory: Invoice.create
    // ================================================================
    group('Invoice.create', () {
      test('sets defaults correctly', () {
        final beforeCreate = DateTime.now();
        final invoice = Invoice.create(
          companyId: 'comp-001',
          createdByUserId: 'user-001',
          invoiceNumber: 'INV-2025-002',
          customerName: 'Jane Doe',
          customerAddress: '456 Oak Ave',
          customerId: 'cust-002',
          taxRate: 7.5,
        );
        final afterCreate = DateTime.now();

        expect(invoice.companyId, 'comp-001');
        expect(invoice.createdByUserId, 'user-001');
        expect(invoice.invoiceNumber, 'INV-2025-002');
        expect(invoice.customerName, 'Jane Doe');
        expect(invoice.customerAddress, '456 Oak Ave');
        expect(invoice.customerId, 'cust-002');
        expect(invoice.taxRate, 7.5);
        expect(invoice.status, InvoiceStatus.draft);
        expect(invoice.jobId, isNull);
        expect(invoice.lineItems, isEmpty);
        expect(invoice.id, '');

        // dueDate should be ~30 days from now
        expect(invoice.dueDate, isNotNull);
        final expectedDue = invoice.createdAt.add(const Duration(days: 30));
        expect(invoice.dueDate!.difference(expectedDue).inSeconds.abs(),
            lessThan(2));

        // createdAt should be between beforeCreate and afterCreate
        expect(
            invoice.createdAt.isAfter(
                beforeCreate.subtract(const Duration(milliseconds: 100))),
            isTrue);
        expect(
            invoice.createdAt
                .isBefore(afterCreate.add(const Duration(milliseconds: 100))),
            isTrue);
      });

      test('does not require customerId', () {
        final invoice = Invoice.create(
          companyId: 'comp-001',
          createdByUserId: 'user-001',
          invoiceNumber: 'INV-001',
          customerName: 'Walk-in',
          customerAddress: 'N/A',
        );
        expect(invoice.customerId, isNull);
      });
    });

    // ================================================================
    // copyWith
    // ================================================================
    group('copyWith', () {
      test('changes status while preserving other fields', () {
        final original = Invoice.fromJson(fullSnakeCaseJson());
        final modified = original.copyWith(status: InvoiceStatus.paid);

        expect(modified.status, InvoiceStatus.paid);
        expect(modified.id, original.id);
        expect(modified.invoiceNumber, original.invoiceNumber);
        expect(modified.customerName, original.customerName);
        expect(modified.lineItems.length, original.lineItems.length);
        expect(modified.subtotal, original.subtotal);
        expect(modified.total, original.total);
        expect(modified.taxRate, original.taxRate);
        expect(modified.dueDate, original.dueDate);
        expect(modified.createdAt, original.createdAt);
      });
    });
  });
}
