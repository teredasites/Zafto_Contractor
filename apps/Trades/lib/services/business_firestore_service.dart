/// ZAFTO Business Firestore Service
/// Handles company-scoped business collections: Jobs, Invoices, Customers, Bids
/// Sprint 16.0 - February 2026

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import '../models/bid.dart';
import 'auth_service.dart';

/// Business Firestore service provider
final businessFirestoreProvider = Provider<BusinessFirestoreService>((ref) {
  final authState = ref.watch(authStateProvider);
  return BusinessFirestoreService(authState);
});

/// Business Firestore Service - Company-scoped collections
class BusinessFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthState _authState;

  BusinessFirestoreService(this._authState);

  String? get _userId => _authState.user?.uid;
  String? get _companyId => _authState.companyId;

  bool get isReady => _userId != null && _companyId != null;

  // ============================================================
  // COLLECTION REFERENCES
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _jobsCollection =>
      _firestore.collection('jobs');

  CollectionReference<Map<String, dynamic>> get _invoicesCollection =>
      _firestore.collection('invoices');

  CollectionReference<Map<String, dynamic>> get _customersCollection =>
      _firestore.collection('customers');

  CollectionReference<Map<String, dynamic>> get _bidsCollection =>
      _firestore.collection('bids');

  // ============================================================
  // JOBS
  // ============================================================

  /// Create a new job
  Future<String> createJob(Job job) async {
    if (!isReady) throw Exception('User not authenticated');

    final docRef = await _jobsCollection.add({
      ...job.toJson(),
      'companyId': _companyId,
      'createdByUserId': _userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'syncedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Update an existing job
  Future<void> updateJob(Job job) async {
    if (!isReady) throw Exception('User not authenticated');

    await _jobsCollection.doc(job.id).update({
      ...job.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
      'syncedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a job
  Future<void> deleteJob(String jobId) async {
    if (!isReady) throw Exception('User not authenticated');
    await _jobsCollection.doc(jobId).delete();
  }

  /// Get a single job
  Future<Job?> getJob(String jobId) async {
    if (!isReady) return null;

    final doc = await _jobsCollection.doc(jobId).get();
    if (!doc.exists || doc.data() == null) return null;

    return Job.fromJson({...doc.data()!, 'id': doc.id});
  }

  /// Get all jobs for current company
  Future<List<Job>> getJobs({
    JobStatus? status,
    String? assignedToUserId,
    int limit = 100,
  }) async {
    if (!isReady) return [];

    Query<Map<String, dynamic>> query = _jobsCollection
        .where('companyId', isEqualTo: _companyId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (assignedToUserId != null) {
      query = query.where('assignedToUserId', isEqualTo: assignedToUserId);
    }

    query = query.orderBy('updatedAt', descending: true).limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return Job.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  /// Stream jobs for real-time updates
  Stream<List<Job>> streamJobs({JobStatus? status}) {
    if (!isReady) return Stream.value([]);

    Query<Map<String, dynamic>> query = _jobsCollection
        .where('companyId', isEqualTo: _companyId)
        .orderBy('updatedAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Job.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }

  /// Get jobs updated since a timestamp (for sync)
  Future<List<Job>> getJobsUpdatedSince(DateTime since) async {
    if (!isReady) return [];

    final snapshot = await _jobsCollection
        .where('companyId', isEqualTo: _companyId)
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(since))
        .get();

    return snapshot.docs.map((doc) {
      return Job.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  // ============================================================
  // INVOICES
  // ============================================================

  /// Create a new invoice
  Future<String> createInvoice(Invoice invoice) async {
    if (!isReady) throw Exception('User not authenticated');

    final docRef = await _invoicesCollection.add({
      ...invoice.toJson(),
      'companyId': _companyId,
      'createdByUserId': _userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'syncedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Update an existing invoice
  Future<void> updateInvoice(Invoice invoice) async {
    if (!isReady) throw Exception('User not authenticated');

    await _invoicesCollection.doc(invoice.id).update({
      ...invoice.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
      'syncedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete an invoice
  Future<void> deleteInvoice(String invoiceId) async {
    if (!isReady) throw Exception('User not authenticated');
    await _invoicesCollection.doc(invoiceId).delete();
  }

  /// Get a single invoice
  Future<Invoice?> getInvoice(String invoiceId) async {
    if (!isReady) return null;

    final doc = await _invoicesCollection.doc(invoiceId).get();
    if (!doc.exists || doc.data() == null) return null;

    return Invoice.fromJson({...doc.data()!, 'id': doc.id});
  }

  /// Get all invoices for current company
  Future<List<Invoice>> getInvoices({
    InvoiceStatus? status,
    int limit = 100,
  }) async {
    if (!isReady) return [];

    Query<Map<String, dynamic>> query = _invoicesCollection
        .where('companyId', isEqualTo: _companyId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return Invoice.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  /// Stream invoices for real-time updates
  Stream<List<Invoice>> streamInvoices({InvoiceStatus? status}) {
    if (!isReady) return Stream.value([]);

    Query<Map<String, dynamic>> query = _invoicesCollection
        .where('companyId', isEqualTo: _companyId)
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Invoice.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }

  /// Get invoices updated since a timestamp (for sync)
  Future<List<Invoice>> getInvoicesUpdatedSince(DateTime since) async {
    if (!isReady) return [];

    final snapshot = await _invoicesCollection
        .where('companyId', isEqualTo: _companyId)
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(since))
        .get();

    return snapshot.docs.map((doc) {
      return Invoice.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  // ============================================================
  // CUSTOMERS
  // ============================================================

  /// Create a new customer
  Future<String> createCustomer(Customer customer) async {
    if (!isReady) throw Exception('User not authenticated');

    final docRef = await _customersCollection.add({
      ...customer.toJson(),
      'companyId': _companyId,
      'createdByUserId': _userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'syncedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Update an existing customer
  Future<void> updateCustomer(Customer customer) async {
    if (!isReady) throw Exception('User not authenticated');

    await _customersCollection.doc(customer.id).update({
      ...customer.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
      'syncedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a customer
  Future<void> deleteCustomer(String customerId) async {
    if (!isReady) throw Exception('User not authenticated');
    await _customersCollection.doc(customerId).delete();
  }

  /// Get a single customer
  Future<Customer?> getCustomer(String customerId) async {
    if (!isReady) return null;

    final doc = await _customersCollection.doc(customerId).get();
    if (!doc.exists || doc.data() == null) return null;

    return Customer.fromJson({...doc.data()!, 'id': doc.id});
  }

  /// Get all customers for current company
  Future<List<Customer>> getCustomers({int limit = 100}) async {
    if (!isReady) return [];

    final snapshot = await _customersCollection
        .where('companyId', isEqualTo: _companyId)
        .orderBy('name')
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      return Customer.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  /// Stream customers for real-time updates
  Stream<List<Customer>> streamCustomers() {
    if (!isReady) return Stream.value([]);

    return _customersCollection
        .where('companyId', isEqualTo: _companyId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Customer.fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }

  /// Search customers by name
  Future<List<Customer>> searchCustomers(String query) async {
    if (!isReady) return [];

    // Firestore doesn't support full-text search natively
    // This is a simple prefix search - consider Algolia for production
    final snapshot = await _customersCollection
        .where('companyId', isEqualTo: _companyId)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs.map((doc) {
      return Customer.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  /// Get customers updated since a timestamp (for sync)
  Future<List<Customer>> getCustomersUpdatedSince(DateTime since) async {
    if (!isReady) return [];

    final snapshot = await _customersCollection
        .where('companyId', isEqualTo: _companyId)
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(since))
        .get();

    return snapshot.docs.map((doc) {
      return Customer.fromJson({...doc.data(), 'id': doc.id});
    }).toList();
  }

  // ============================================================
  // BATCH OPERATIONS
  // ============================================================

  /// Batch sync multiple jobs
  Future<void> batchSyncJobs(List<Job> jobs) async {
    if (!isReady) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    for (final job in jobs) {
      final docRef = _jobsCollection.doc(job.id);
      batch.set(docRef, {
        ...job.toJson(),
        'companyId': _companyId,
        'syncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Batch sync multiple invoices
  Future<void> batchSyncInvoices(List<Invoice> invoices) async {
    if (!isReady) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    for (final invoice in invoices) {
      final docRef = _invoicesCollection.doc(invoice.id);
      batch.set(docRef, {
        ...invoice.toJson(),
        'companyId': _companyId,
        'syncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Batch sync multiple customers
  Future<void> batchSyncCustomers(List<Customer> customers) async {
    if (!isReady) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    for (final customer in customers) {
      final docRef = _customersCollection.doc(customer.id);
      batch.set(docRef, {
        ...customer.toJson(),
        'companyId': _companyId,
        'syncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // ============================================================
  // STATS & AGGREGATES
  // ============================================================

  /// Get job counts by status
  Future<Map<JobStatus, int>> getJobCountsByStatus() async {
    if (!isReady) return {};

    final counts = <JobStatus, int>{};

    for (final status in JobStatus.values) {
      final snapshot = await _jobsCollection
          .where('companyId', isEqualTo: _companyId)
          .where('status', isEqualTo: status.name)
          .count()
          .get();
      counts[status] = snapshot.count ?? 0;
    }

    return counts;
  }

  /// Get invoice totals by status
  Future<Map<InvoiceStatus, double>> getInvoiceTotalsByStatus() async {
    if (!isReady) return {};

    final totals = <InvoiceStatus, double>{};

    for (final status in InvoiceStatus.values) {
      final snapshot = await _invoicesCollection
          .where('companyId', isEqualTo: _companyId)
          .where('status', isEqualTo: status.name)
          .get();

      double total = 0;
      for (final doc in snapshot.docs) {
        total += (doc.data()['total'] as num?)?.toDouble() ?? 0;
      }
      totals[status] = total;
    }

    return totals;
  }

  /// Get customer count
  Future<int> getCustomerCount() async {
    if (!isReady) return 0;

    final snapshot = await _customersCollection
        .where('companyId', isEqualTo: _companyId)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // ============================================================
  // BIDS
  // ============================================================

  /// Create a new bid
  Future<String> createBid(Bid bid) async {
    if (!isReady) throw Exception('User not authenticated');

    final docRef = await _bidsCollection.add({
      ...bid.toMap(),
      'companyId': _companyId,
      'createdByUserId': _userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'syncedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Update an existing bid
  Future<void> updateBid(Bid bid) async {
    if (!isReady) throw Exception('User not authenticated');

    await _bidsCollection.doc(bid.id).update({
      ...bid.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'syncedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a bid
  Future<void> deleteBid(String bidId) async {
    if (!isReady) throw Exception('User not authenticated');
    await _bidsCollection.doc(bidId).delete();
  }

  /// Get a single bid
  Future<Bid?> getBid(String bidId) async {
    if (!isReady) return null;

    final doc = await _bidsCollection.doc(bidId).get();
    if (!doc.exists || doc.data() == null) return null;

    return Bid.fromMap({...doc.data()!, 'id': doc.id});
  }

  /// Get a bid by access token (for client portal)
  Future<Bid?> getBidByAccessToken(String accessToken) async {
    final snapshot = await _bidsCollection
        .where('accessToken', isEqualTo: accessToken)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return Bid.fromMap({...doc.data(), 'id': doc.id});
  }

  /// Get all bids for current company
  Future<List<Bid>> getBids({
    BidStatus? status,
    String? customerId,
    int limit = 100,
  }) async {
    if (!isReady) return [];

    Query<Map<String, dynamic>> query = _bidsCollection
        .where('companyId', isEqualTo: _companyId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (customerId != null) {
      query = query.where('customerId', isEqualTo: customerId);
    }

    query = query.orderBy('updatedAt', descending: true).limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return Bid.fromMap({...doc.data(), 'id': doc.id});
    }).toList();
  }

  /// Stream bids for real-time updates
  Stream<List<Bid>> streamBids({BidStatus? status}) {
    if (!isReady) return Stream.value([]);

    Query<Map<String, dynamic>> query = _bidsCollection
        .where('companyId', isEqualTo: _companyId)
        .orderBy('updatedAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Bid.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }

  /// Get bids updated since a timestamp (for sync)
  Future<List<Bid>> getBidsUpdatedSince(DateTime since) async {
    if (!isReady) return [];

    final snapshot = await _bidsCollection
        .where('companyId', isEqualTo: _companyId)
        .where('updatedAt', isGreaterThan: Timestamp.fromDate(since))
        .get();

    return snapshot.docs.map((doc) {
      return Bid.fromMap({...doc.data(), 'id': doc.id});
    }).toList();
  }

  /// Batch sync multiple bids
  Future<void> batchSyncBids(List<Bid> bids) async {
    if (!isReady) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    for (final bid in bids) {
      final docRef = _bidsCollection.doc(bid.id);
      batch.set(docRef, {
        ...bid.toMap(),
        'companyId': _companyId,
        'syncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Get bid counts by status
  Future<Map<BidStatus, int>> getBidCountsByStatus() async {
    if (!isReady) return {};

    final counts = <BidStatus, int>{};

    for (final status in BidStatus.values) {
      final snapshot = await _bidsCollection
          .where('companyId', isEqualTo: _companyId)
          .where('status', isEqualTo: status.name)
          .count()
          .get();
      counts[status] = snapshot.count ?? 0;
    }

    return counts;
  }

  /// Get bid totals by status
  Future<Map<BidStatus, double>> getBidTotalsByStatus() async {
    if (!isReady) return {};

    final totals = <BidStatus, double>{};

    for (final status in BidStatus.values) {
      final snapshot = await _bidsCollection
          .where('companyId', isEqualTo: _companyId)
          .where('status', isEqualTo: status.name)
          .get();

      double total = 0;
      for (final doc in snapshot.docs) {
        total += (doc.data()['total'] as num?)?.toDouble() ?? 0;
      }
      totals[status] = total;
    }

    return totals;
  }

  /// Get bid win rate (accepted / (accepted + declined))
  Future<double> getBidWinRate() async {
    if (!isReady) return 0.0;

    final acceptedSnapshot = await _bidsCollection
        .where('companyId', isEqualTo: _companyId)
        .where('status', whereIn: ['accepted', 'converted'])
        .count()
        .get();

    final declinedSnapshot = await _bidsCollection
        .where('companyId', isEqualTo: _companyId)
        .where('status', isEqualTo: 'declined')
        .count()
        .get();

    final accepted = acceptedSnapshot.count ?? 0;
    final declined = declinedSnapshot.count ?? 0;
    final total = accepted + declined;

    if (total == 0) return 0.0;
    return accepted / total * 100;
  }
}
