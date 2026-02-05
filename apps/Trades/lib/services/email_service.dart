import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice.dart';
import '../models/company.dart';
import '../models/job.dart';
import '../models/customer.dart';

/// Email template types
enum EmailTemplate {
  invoiceSend,           // Invoice to customer
  invoiceReminder,       // Payment reminder
  invoiceReceipt,        // Payment received confirmation
  jobScheduled,          // Job scheduling confirmation
  jobStarting,           // Job starting notification
  jobCompleted,          // Job completion summary
  welcome,               // New customer welcome
  custom,                // Custom email
}

/// Email status tracking
enum EmailStatus {
  pending,    // Queued for sending
  sent,       // Successfully sent
  delivered,  // Confirmed delivered (if tracking available)
  opened,     // Email opened (if tracking available)
  clicked,    // Link clicked (if tracking available)
  failed,     // Failed to send
  bounced,    // Email bounced
}

/// Email record model
class EmailRecord {
  final String id;
  final String companyId;
  final String? jobId;
  final String? invoiceId;
  final String? customerId;
  final EmailTemplate template;
  final String recipientEmail;
  final String recipientName;
  final String subject;
  final String? previewText;
  final EmailStatus status;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? openedAt;
  final String? trackingId;

  const EmailRecord({
    required this.id,
    required this.companyId,
    this.jobId,
    this.invoiceId,
    this.customerId,
    required this.template,
    required this.recipientEmail,
    required this.recipientName,
    required this.subject,
    this.previewText,
    required this.status,
    this.failureReason,
    required this.createdAt,
    this.sentAt,
    this.openedAt,
    this.trackingId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'jobId': jobId,
      'invoiceId': invoiceId,
      'customerId': customerId,
      'template': template.name,
      'recipientEmail': recipientEmail,
      'recipientName': recipientName,
      'subject': subject,
      'previewText': previewText,
      'status': status.name,
      'failureReason': failureReason,
      'createdAt': createdAt.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'openedAt': openedAt?.toIso8601String(),
      'trackingId': trackingId,
    };
  }

  factory EmailRecord.fromMap(Map<String, dynamic> map) {
    return EmailRecord(
      id: map['id'] as String,
      companyId: map['companyId'] as String,
      jobId: map['jobId'] as String?,
      invoiceId: map['invoiceId'] as String?,
      customerId: map['customerId'] as String?,
      template: EmailTemplate.values.firstWhere(
        (t) => t.name == map['template'],
        orElse: () => EmailTemplate.custom,
      ),
      recipientEmail: map['recipientEmail'] as String,
      recipientName: map['recipientName'] as String,
      subject: map['subject'] as String,
      previewText: map['previewText'] as String?,
      status: EmailStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => EmailStatus.pending,
      ),
      failureReason: map['failureReason'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      sentAt: map['sentAt'] != null ? DateTime.parse(map['sentAt'] as String) : null,
      openedAt: map['openedAt'] != null ? DateTime.parse(map['openedAt'] as String) : null,
      trackingId: map['trackingId'] as String?,
    );
  }
}

/// Service for sending emails via Cloud Functions
class EmailService {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final Uuid _uuid = const Uuid();

  EmailService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>> _emailsRef(String companyId) =>
      _firestore.collection('companies').doc(companyId).collection('emails');

  // ============================================================
  // INVOICE EMAILS
  // ============================================================

  /// Send invoice to customer
  Future<EmailRecord> sendInvoice({
    required Invoice invoice,
    required Company company,
    Uint8List? pdfAttachment,
    String? customMessage,
  }) async {
    if (invoice.customerEmail == null || invoice.customerEmail!.isEmpty) {
      throw Exception('Customer email is required');
    }

    final emailId = _uuid.v4();
    final now = DateTime.now();

    // Create email record
    final record = EmailRecord(
      id: emailId,
      companyId: invoice.companyId,
      invoiceId: invoice.id,
      customerId: invoice.customerId,
      template: EmailTemplate.invoiceSend,
      recipientEmail: invoice.customerEmail!,
      recipientName: invoice.customerName,
      subject: 'Invoice #${invoice.invoiceNumber} from ${company.name}',
      previewText: 'Amount due: \$${invoice.total.toStringAsFixed(2)}',
      status: EmailStatus.pending,
      createdAt: now,
    );

    // Save record
    await _emailsRef(invoice.companyId).doc(emailId).set(record.toMap());

    // Call Cloud Function to send email
    try {
      final callable = _functions.httpsCallable('sendInvoiceEmail');
      await callable.call({
        'emailId': emailId,
        'companyId': invoice.companyId,
        'invoiceId': invoice.id,
        'recipientEmail': invoice.customerEmail,
        'recipientName': invoice.customerName,
        'subject': record.subject,
        'companyName': company.name,
        'companyEmail': company.email,
        'companyPhone': company.phone,
        'invoiceNumber': invoice.invoiceNumber,
        'invoiceDate': invoice.createdAt.toIso8601String(),
        'dueDate': invoice.dueDate?.toIso8601String() ?? '',
        'amount': invoice.total,
        'customMessage': customMessage,
        'hasPdfAttachment': pdfAttachment != null,
      });

      // Update status
      await _emailsRef(invoice.companyId).doc(emailId).update({
        'status': EmailStatus.sent.name,
        'sentAt': DateTime.now().toIso8601String(),
      });

      return record.copyWith(status: EmailStatus.sent, sentAt: DateTime.now());
    } catch (e) {
      // Update status on failure
      await _emailsRef(invoice.companyId).doc(emailId).update({
        'status': EmailStatus.failed.name,
        'failureReason': e.toString(),
      });

      throw Exception('Failed to send email: $e');
    }
  }

  /// Send payment reminder
  Future<EmailRecord> sendPaymentReminder({
    required Invoice invoice,
    required Company company,
    int reminderNumber = 1,
  }) async {
    if (invoice.customerEmail == null || invoice.customerEmail!.isEmpty) {
      throw Exception('Customer email is required');
    }

    final emailId = _uuid.v4();
    final now = DateTime.now();
    final isOverdue = invoice.isOverdue;

    String subject;
    if (isOverdue) {
      subject = 'OVERDUE: Invoice #${invoice.invoiceNumber} - Payment Required';
    } else if (reminderNumber == 1) {
      subject = 'Reminder: Invoice #${invoice.invoiceNumber} Due Soon';
    } else {
      subject = 'Final Notice: Invoice #${invoice.invoiceNumber}';
    }

    final record = EmailRecord(
      id: emailId,
      companyId: invoice.companyId,
      invoiceId: invoice.id,
      customerId: invoice.customerId,
      template: EmailTemplate.invoiceReminder,
      recipientEmail: invoice.customerEmail!,
      recipientName: invoice.customerName,
      subject: subject,
      previewText: 'Balance due: \$${invoice.amountDue.toStringAsFixed(2)}',
      status: EmailStatus.pending,
      createdAt: now,
    );

    await _emailsRef(invoice.companyId).doc(emailId).set(record.toMap());

    try {
      final callable = _functions.httpsCallable('sendPaymentReminder');
      await callable.call({
        'emailId': emailId,
        'companyId': invoice.companyId,
        'invoiceId': invoice.id,
        'recipientEmail': invoice.customerEmail,
        'recipientName': invoice.customerName,
        'subject': subject,
        'companyName': company.name,
        'invoiceNumber': invoice.invoiceNumber,
        'amountDue': invoice.amountDue,
        'dueDate': invoice.dueDate?.toIso8601String() ?? '',
        'isOverdue': isOverdue,
        'daysOverdue': isOverdue && invoice.dueDate != null
            ? DateTime.now().difference(invoice.dueDate!).inDays
            : 0,
        'reminderNumber': reminderNumber,
      });

      await _emailsRef(invoice.companyId).doc(emailId).update({
        'status': EmailStatus.sent.name,
        'sentAt': DateTime.now().toIso8601String(),
      });

      return record.copyWith(status: EmailStatus.sent, sentAt: DateTime.now());
    } catch (e) {
      await _emailsRef(invoice.companyId).doc(emailId).update({
        'status': EmailStatus.failed.name,
        'failureReason': e.toString(),
      });
      throw Exception('Failed to send reminder: $e');
    }
  }

  /// Send payment receipt
  Future<EmailRecord> sendPaymentReceipt({
    required Invoice invoice,
    required Company company,
    required double paymentAmount,
    required String paymentMethod,
  }) async {
    if (invoice.customerEmail == null || invoice.customerEmail!.isEmpty) {
      throw Exception('Customer email is required');
    }

    final emailId = _uuid.v4();
    final now = DateTime.now();

    final record = EmailRecord(
      id: emailId,
      companyId: invoice.companyId,
      invoiceId: invoice.id,
      customerId: invoice.customerId,
      template: EmailTemplate.invoiceReceipt,
      recipientEmail: invoice.customerEmail!,
      recipientName: invoice.customerName,
      subject: 'Payment Received - Thank You!',
      previewText: 'We received your payment of \$${paymentAmount.toStringAsFixed(2)}',
      status: EmailStatus.pending,
      createdAt: now,
    );

    await _emailsRef(invoice.companyId).doc(emailId).set(record.toMap());

    try {
      final callable = _functions.httpsCallable('sendPaymentReceipt');
      await callable.call({
        'emailId': emailId,
        'companyId': invoice.companyId,
        'invoiceId': invoice.id,
        'recipientEmail': invoice.customerEmail,
        'recipientName': invoice.customerName,
        'companyName': company.name,
        'invoiceNumber': invoice.invoiceNumber,
        'paymentAmount': paymentAmount,
        'paymentMethod': paymentMethod,
        'remainingBalance': invoice.amountDue - paymentAmount,
      });

      await _emailsRef(invoice.companyId).doc(emailId).update({
        'status': EmailStatus.sent.name,
        'sentAt': DateTime.now().toIso8601String(),
      });

      return record.copyWith(status: EmailStatus.sent, sentAt: DateTime.now());
    } catch (e) {
      await _emailsRef(invoice.companyId).doc(emailId).update({
        'status': EmailStatus.failed.name,
        'failureReason': e.toString(),
      });
      throw Exception('Failed to send receipt: $e');
    }
  }

  // ============================================================
  // JOB EMAILS
  // ============================================================

  /// Send job scheduling confirmation
  Future<EmailRecord> sendJobScheduledEmail({
    required Job job,
    required Company company,
    required Customer customer,
  }) async {
    if (customer.email == null || customer.email!.isEmpty) {
      throw Exception('Customer email is required');
    }

    final emailId = _uuid.v4();
    final now = DateTime.now();

    final record = EmailRecord(
      id: emailId,
      companyId: job.companyId,
      jobId: job.id,
      customerId: customer.id,
      template: EmailTemplate.jobScheduled,
      recipientEmail: customer.email!,
      recipientName: customer.displayName,
      subject: 'Service Appointment Scheduled - ${company.name}',
      previewText: job.scheduledStart != null
          ? 'Your appointment is scheduled for ${_formatDate(job.scheduledStart!)}'
          : 'Your service appointment has been scheduled',
      status: EmailStatus.pending,
      createdAt: now,
    );

    await _emailsRef(job.companyId).doc(emailId).set(record.toMap());

    try {
      final callable = _functions.httpsCallable('sendJobScheduledEmail');
      await callable.call({
        'emailId': emailId,
        'companyId': job.companyId,
        'jobId': job.id,
        'recipientEmail': customer.email,
        'recipientName': customer.displayName,
        'companyName': company.name,
        'companyPhone': company.phone,
        'scheduledDate': job.scheduledStart?.toIso8601String(),
        'scheduledEndDate': job.scheduledEnd?.toIso8601String(),
        'serviceAddress': job.fullAddress,
        'jobTitle': job.title,
        'jobDescription': job.description,
      });

      await _emailsRef(job.companyId).doc(emailId).update({
        'status': EmailStatus.sent.name,
        'sentAt': DateTime.now().toIso8601String(),
      });

      return record.copyWith(status: EmailStatus.sent, sentAt: DateTime.now());
    } catch (e) {
      await _emailsRef(job.companyId).doc(emailId).update({
        'status': EmailStatus.failed.name,
        'failureReason': e.toString(),
      });
      throw Exception('Failed to send email: $e');
    }
  }

  /// Send job completion email
  Future<EmailRecord> sendJobCompletedEmail({
    required Job job,
    required Company company,
    required Customer customer,
    String? summary,
  }) async {
    if (customer.email == null || customer.email!.isEmpty) {
      throw Exception('Customer email is required');
    }

    final emailId = _uuid.v4();
    final now = DateTime.now();

    final record = EmailRecord(
      id: emailId,
      companyId: job.companyId,
      jobId: job.id,
      customerId: customer.id,
      template: EmailTemplate.jobCompleted,
      recipientEmail: customer.email!,
      recipientName: customer.displayName,
      subject: 'Service Completed - ${company.name}',
      previewText: 'Your service has been completed. Thank you for choosing us!',
      status: EmailStatus.pending,
      createdAt: now,
    );

    await _emailsRef(job.companyId).doc(emailId).set(record.toMap());

    try {
      final callable = _functions.httpsCallable('sendJobCompletedEmail');
      await callable.call({
        'emailId': emailId,
        'companyId': job.companyId,
        'jobId': job.id,
        'recipientEmail': customer.email,
        'recipientName': customer.displayName,
        'companyName': company.name,
        'completedDate': job.completedAt?.toIso8601String(),
        'jobTitle': job.title,
        'summary': summary ?? job.description,
        'serviceAddress': job.fullAddress,
      });

      await _emailsRef(job.companyId).doc(emailId).update({
        'status': EmailStatus.sent.name,
        'sentAt': DateTime.now().toIso8601String(),
      });

      return record.copyWith(status: EmailStatus.sent, sentAt: DateTime.now());
    } catch (e) {
      await _emailsRef(job.companyId).doc(emailId).update({
        'status': EmailStatus.failed.name,
        'failureReason': e.toString(),
      });
      throw Exception('Failed to send email: $e');
    }
  }

  // ============================================================
  // CUSTOM EMAILS
  // ============================================================

  /// Send custom email
  Future<EmailRecord> sendCustomEmail({
    required String companyId,
    required Company company,
    required String recipientEmail,
    required String recipientName,
    required String subject,
    required String body,
    String? customerId,
    String? jobId,
    String? invoiceId,
    List<String>? attachmentUrls,
  }) async {
    final emailId = _uuid.v4();
    final now = DateTime.now();

    final record = EmailRecord(
      id: emailId,
      companyId: companyId,
      jobId: jobId,
      invoiceId: invoiceId,
      customerId: customerId,
      template: EmailTemplate.custom,
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: subject,
      status: EmailStatus.pending,
      createdAt: now,
    );

    await _emailsRef(companyId).doc(emailId).set(record.toMap());

    try {
      final callable = _functions.httpsCallable('sendCustomEmail');
      await callable.call({
        'emailId': emailId,
        'companyId': companyId,
        'recipientEmail': recipientEmail,
        'recipientName': recipientName,
        'subject': subject,
        'body': body,
        'companyName': company.name,
        'companyEmail': company.email,
        'attachmentUrls': attachmentUrls ?? [],
      });

      await _emailsRef(companyId).doc(emailId).update({
        'status': EmailStatus.sent.name,
        'sentAt': DateTime.now().toIso8601String(),
      });

      return record.copyWith(status: EmailStatus.sent, sentAt: DateTime.now());
    } catch (e) {
      await _emailsRef(companyId).doc(emailId).update({
        'status': EmailStatus.failed.name,
        'failureReason': e.toString(),
      });
      throw Exception('Failed to send email: $e');
    }
  }

  // ============================================================
  // READ
  // ============================================================

  /// Get email history for a company
  Future<List<EmailRecord>> getEmailHistory(
    String companyId, {
    int limit = 50,
    EmailStatus? status,
  }) async {
    Query<Map<String, dynamic>> query = _emailsRef(companyId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => EmailRecord.fromMap(doc.data())).toList();
  }

  /// Get emails for a specific customer
  Future<List<EmailRecord>> getCustomerEmails(
    String companyId,
    String customerId,
  ) async {
    final snapshot = await _emailsRef(companyId)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => EmailRecord.fromMap(doc.data())).toList();
  }

  /// Get emails for a specific invoice
  Future<List<EmailRecord>> getInvoiceEmails(
    String companyId,
    String invoiceId,
  ) async {
    final snapshot = await _emailsRef(companyId)
        .where('invoiceId', isEqualTo: invoiceId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => EmailRecord.fromMap(doc.data())).toList();
  }

  /// Get single email record
  Future<EmailRecord?> getEmail(String companyId, String emailId) async {
    final doc = await _emailsRef(companyId).doc(emailId).get();
    if (!doc.exists) return null;
    return EmailRecord.fromMap(doc.data()!);
  }

  // ============================================================
  // RETRY
  // ============================================================

  /// Retry a failed email
  Future<EmailRecord> retryEmail(String companyId, String emailId) async {
    final email = await getEmail(companyId, emailId);
    if (email == null) throw Exception('Email not found');

    if (email.status != EmailStatus.failed) {
      throw Exception('Can only retry failed emails');
    }

    // Reset status and try again
    await _emailsRef(companyId).doc(emailId).update({
      'status': EmailStatus.pending.name,
      'failureReason': null,
    });

    try {
      final callable = _functions.httpsCallable('retryEmail');
      await callable.call({
        'emailId': emailId,
        'companyId': companyId,
      });

      await _emailsRef(companyId).doc(emailId).update({
        'status': EmailStatus.sent.name,
        'sentAt': DateTime.now().toIso8601String(),
      });

      return email.copyWith(status: EmailStatus.sent, sentAt: DateTime.now());
    } catch (e) {
      await _emailsRef(companyId).doc(emailId).update({
        'status': EmailStatus.failed.name,
        'failureReason': e.toString(),
      });
      throw Exception('Retry failed: $e');
    }
  }

  // ============================================================
  // UTILITIES
  // ============================================================

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $ampm';
  }
}

// Extension for copyWith
extension _EmailRecordCopyWith on EmailRecord {
  EmailRecord copyWith({
    EmailStatus? status,
    DateTime? sentAt,
    String? failureReason,
  }) {
    return EmailRecord(
      id: id,
      companyId: companyId,
      jobId: jobId,
      invoiceId: invoiceId,
      customerId: customerId,
      template: template,
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      subject: subject,
      previewText: previewText,
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt,
      sentAt: sentAt ?? this.sentAt,
      openedAt: openedAt,
      trackingId: trackingId,
    );
  }
}

// ============================================================
// PROVIDERS
// ============================================================

/// Provider for EmailService
final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService();
});

/// Provider for email history
final emailHistoryProvider =
    FutureProvider.family<List<EmailRecord>, String>((ref, companyId) {
  return ref.watch(emailServiceProvider).getEmailHistory(companyId);
});

/// Provider for customer emails
final customerEmailsProvider = FutureProvider.family<List<EmailRecord>,
    ({String companyId, String customerId})>((ref, params) {
  return ref
      .watch(emailServiceProvider)
      .getCustomerEmails(params.companyId, params.customerId);
});

/// Provider for invoice emails
final invoiceEmailsProvider = FutureProvider.family<List<EmailRecord>,
    ({String companyId, String invoiceId})>((ref, params) {
  return ref
      .watch(emailServiceProvider)
      .getInvoiceEmails(params.companyId, params.invoiceId);
});
