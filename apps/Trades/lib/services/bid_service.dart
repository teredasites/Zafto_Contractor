/// ZAFTO Bid Service - Offline-First with Cloud Sync
/// Sprint 16.0 - February 2026

import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/bid.dart';
import '../models/bid_template.dart';
import 'business_firestore_service.dart';
import 'auth_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

final bidServiceProvider = Provider<BidService>((ref) {
  final businessFirestore = ref.watch(businessFirestoreProvider);
  final authState = ref.watch(authStateProvider);
  return BidService(businessFirestore, authState);
});

final bidsProvider = StateNotifierProvider<BidsNotifier, AsyncValue<List<Bid>>>((ref) {
  final service = ref.watch(bidServiceProvider);
  return BidsNotifier(service, ref);
});

/// All draft bids
final draftBidsProvider = Provider<List<Bid>>((ref) {
  final bids = ref.watch(bidsProvider);
  return bids.maybeWhen(
    data: (list) => list.where((b) => b.status == BidStatus.draft).toList(),
    orElse: () => [],
  );
});

/// All pending bids (sent, viewed)
final pendingBidsProvider = Provider<List<Bid>>((ref) {
  final bids = ref.watch(bidsProvider);
  return bids.maybeWhen(
    data: (list) => list.where((b) => b.isPending).toList(),
    orElse: () => [],
  );
});

/// All accepted bids
final acceptedBidsProvider = Provider<List<Bid>>((ref) {
  final bids = ref.watch(bidsProvider);
  return bids.maybeWhen(
    data: (list) => list.where((b) => b.isAccepted).toList(),
    orElse: () => [],
  );
});

/// Bid statistics
final bidStatsProvider = Provider<BidStats>((ref) {
  final bids = ref.watch(bidsProvider);
  return bids.maybeWhen(
    data: (list) {
      final total = list.length;
      final drafts = list.where((b) => b.status == BidStatus.draft).length;
      final sent = list.where((b) =>
        b.status == BidStatus.sent || b.status == BidStatus.viewed
      ).length;
      final accepted = list.where((b) =>
        b.status == BidStatus.accepted || b.status == BidStatus.converted
      ).length;
      final declined = list.where((b) => b.status == BidStatus.declined).length;

      final acceptedBids = list.where((b) =>
        b.status == BidStatus.accepted || b.status == BidStatus.converted
      );
      final totalValue = acceptedBids.fold<double>(0.0, (sum, b) => sum + b.total);

      final pendingBids = list.where((b) =>
        b.status == BidStatus.sent || b.status == BidStatus.viewed
      );
      final pendingValue = pendingBids.fold<double>(0.0, (sum, b) => sum + b.total);

      // Win rate: accepted / (accepted + declined)
      final decisions = accepted + declined;
      final winRate = decisions > 0 ? (accepted / decisions * 100) : 0.0;

      return BidStats(
        totalBids: total,
        draftBids: drafts,
        sentBids: sent,
        acceptedBids: accepted,
        declinedBids: declined,
        totalValue: totalValue,
        pendingValue: pendingValue,
        winRate: winRate,
      );
    },
    orElse: () => BidStats.empty(),
  );
});

/// Sync status for bids
final bidSyncStatusProvider = StateProvider<BidSyncStatus>((ref) => BidSyncStatus.idle);

enum BidSyncStatus { idle, syncing, synced, error, offline }

// ============================================================
// STATS MODEL
// ============================================================

class BidStats {
  final int totalBids;
  final int draftBids;
  final int sentBids;
  final int acceptedBids;
  final int declinedBids;
  final double totalValue;
  final double pendingValue;
  final double winRate;

  const BidStats({
    required this.totalBids,
    required this.draftBids,
    required this.sentBids,
    required this.acceptedBids,
    required this.declinedBids,
    required this.totalValue,
    required this.pendingValue,
    required this.winRate,
  });

  factory BidStats.empty() => const BidStats(
    totalBids: 0,
    draftBids: 0,
    sentBids: 0,
    acceptedBids: 0,
    declinedBids: 0,
    totalValue: 0,
    pendingValue: 0,
    winRate: 0,
  );

  String get totalValueDisplay => '\$${totalValue.toStringAsFixed(2)}';
  String get pendingValueDisplay => '\$${pendingValue.toStringAsFixed(2)}';
  String get winRateDisplay => '${winRate.toStringAsFixed(1)}%';
}

// ============================================================
// BIDS NOTIFIER
// ============================================================

class BidsNotifier extends StateNotifier<AsyncValue<List<Bid>>> {
  final BidService _service;
  final Ref _ref;

  BidsNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    loadBids();
  }

  Future<void> loadBids() async {
    state = const AsyncValue.loading();
    try {
      final bids = await _service.getAllBids();
      state = AsyncValue.data(bids);

      // Try to sync with cloud in background
      _syncInBackground();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _syncInBackground() async {
    try {
      _ref.read(bidSyncStatusProvider.notifier).state = BidSyncStatus.syncing;
      await _service.syncWithCloud();

      // Reload after sync
      final bids = await _service.getAllBids();
      state = AsyncValue.data(bids);

      _ref.read(bidSyncStatusProvider.notifier).state = BidSyncStatus.synced;
    } catch (e) {
      _ref.read(bidSyncStatusProvider.notifier).state = BidSyncStatus.error;
    }
  }

  Future<void> addBid(Bid bid) async {
    await _service.saveBid(bid);
    await loadBids();
  }

  Future<void> updateBid(Bid bid) async {
    await _service.saveBid(bid);
    await loadBids();
  }

  Future<void> deleteBid(String id) async {
    await _service.deleteBid(id);
    await loadBids();
  }

  Future<void> forceSync() async {
    await _syncInBackground();
  }
}

// ============================================================
// BID SERVICE
// ============================================================

class BidService {
  static const _boxName = 'bids';
  static const _syncMetaBox = 'bids_sync_meta';
  static const _templateBox = 'bid_templates';
  static const _lineItemLibraryBox = 'line_item_library';

  final BusinessFirestoreService _cloudService;
  final AuthState _authState;

  BidService(this._cloudService, this._authState);

  bool get _isLoggedIn => _authState.isAuthenticated && _authState.hasCompany;
  String? get _companyId => _authState.companyId;
  String? get _userId => _authState.user?.uid;

  // ==================== LOCAL STORAGE ====================

  Future<Box<String>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<String>(_boxName);
    }
    return Hive.box<String>(_boxName);
  }

  Future<Box<String>> _getSyncMetaBox() async {
    if (!Hive.isBoxOpen(_syncMetaBox)) {
      return await Hive.openBox<String>(_syncMetaBox);
    }
    return Hive.box<String>(_syncMetaBox);
  }

  Future<Box<String>> _getTemplateBox() async {
    if (!Hive.isBoxOpen(_templateBox)) {
      return await Hive.openBox<String>(_templateBox);
    }
    return Hive.box<String>(_templateBox);
  }

  /// Get all bids from local storage
  Future<List<Bid>> getAllBids() async {
    final box = await _getBox();
    final bids = <Bid>[];

    for (final key in box.keys) {
      final json = box.get(key);
      if (json != null) {
        try {
          bids.add(Bid.fromMap(jsonDecode(json)));
        } catch (_) {}
      }
    }

    bids.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return bids;
  }

  /// Get bids by status
  Future<List<Bid>> getBidsByStatus(BidStatus status) async {
    final all = await getAllBids();
    return all.where((b) => b.status == status).toList();
  }

  /// Get bids for a customer
  Future<List<Bid>> getBidsForCustomer(String customerId) async {
    final all = await getAllBids();
    return all.where((b) => b.customerId == customerId).toList();
  }

  /// Get a single bid
  Future<Bid?> getBid(String id) async {
    final box = await _getBox();
    final json = box.get(id);
    if (json == null) return null;
    return Bid.fromMap(jsonDecode(json));
  }

  /// Save bid locally (and queue for cloud sync)
  Future<void> saveBid(Bid bid) async {
    final box = await _getBox();

    // Mark as needing sync
    final bidWithSync = bid.copyWith(
      updatedAt: DateTime.now(),
      syncedToCloud: false,
    );

    await box.put(bid.id, jsonEncode(bidWithSync.toMap()));

    // Mark for sync
    await _markForSync(bid.id);

    // Try immediate cloud sync if online
    if (_isLoggedIn) {
      _trySyncBid(bidWithSync);
    }
  }

  /// Delete bid locally (and queue deletion for cloud)
  Future<void> deleteBid(String id) async {
    final box = await _getBox();
    await box.delete(id);

    // Mark deletion for sync
    await _markDeletionForSync(id);

    // Try immediate cloud delete if online
    if (_isLoggedIn) {
      try {
        await _cloudService.deleteBid(id);
      } catch (_) {}
    }
  }

  /// Generate unique bid ID
  String generateId() => 'bid_${DateTime.now().millisecondsSinceEpoch}';

  /// Generate bid number (BID-YYYYMMDD-XXX)
  Future<String> generateBidNumber() async {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // Get count of bids today for sequence
    final all = await getAllBids();
    final todayBids = all.where((b) {
      final created = b.createdAt;
      return created.year == now.year &&
             created.month == now.month &&
             created.day == now.day;
    }).length;

    final sequence = (todayBids + 1).toString().padLeft(3, '0');
    return 'BID-$dateStr-$sequence';
  }

  /// Generate unique access token for client portal
  String generateAccessToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // ==================== BID OPERATIONS ====================

  /// Send bid to customer (generates access token, updates status)
  Future<Bid> sendBid(Bid bid) async {
    if (bid.status != BidStatus.draft) {
      throw Exception('Can only send draft bids');
    }
    if (bid.options.isEmpty) {
      throw Exception('Bid must have at least one option');
    }

    final sentBid = bid.copyWith(
      status: BidStatus.sent,
      accessToken: generateAccessToken(),
      sentAt: DateTime.now(),
    );

    await saveBid(sentBid);
    return sentBid;
  }

  /// Mark bid as viewed
  Future<Bid> markBidViewed(String bidId, {String? viewerIp}) async {
    final bid = await getBid(bidId);
    if (bid == null) throw Exception('Bid not found');

    // Only update if first view
    if (bid.viewedAt == null) {
      final viewedBid = bid.copyWith(
        status: BidStatus.viewed,
        viewedAt: DateTime.now(),
        viewedByIp: viewerIp,
      );
      await saveBid(viewedBid);
      return viewedBid;
    }
    return bid;
  }

  /// Accept bid (customer selected option, signed)
  Future<Bid> acceptBid(
    String bidId, {
    required String selectedOptionId,
    required String signatureData,
    required String signedByName,
    List<String>? selectedAddOnIds,
  }) async {
    final bid = await getBid(bidId);
    if (bid == null) throw Exception('Bid not found');
    if (!bid.isPending) throw Exception('Bid is not pending');

    // Update add-ons selection
    final updatedAddOns = bid.addOns.map((addon) {
      final isSelected = selectedAddOnIds?.contains(addon.id) ?? false;
      return addon.copyWith(isSelected: isSelected);
    }).toList();

    var acceptedBid = bid.copyWith(
      status: BidStatus.accepted,
      selectedOptionId: selectedOptionId,
      addOns: updatedAddOns,
      signatureData: signatureData,
      signedByName: signedByName,
      signedAt: DateTime.now(),
      respondedAt: DateTime.now(),
    );

    // Recalculate totals with selections
    acceptedBid = acceptedBid.recalculate();

    await saveBid(acceptedBid);
    return acceptedBid;
  }

  /// Decline bid
  Future<Bid> declineBid(String bidId, {String? reason}) async {
    final bid = await getBid(bidId);
    if (bid == null) throw Exception('Bid not found');
    if (!bid.isPending) throw Exception('Bid is not pending');

    final declinedBid = bid.copyWith(
      status: BidStatus.declined,
      declineReason: reason,
      respondedAt: DateTime.now(),
    );

    await saveBid(declinedBid);
    return declinedBid;
  }

  /// Record deposit payment
  Future<Bid> recordDepositPayment(
    String bidId, {
    required String paymentId,
    required String paymentMethod,
  }) async {
    final bid = await getBid(bidId);
    if (bid == null) throw Exception('Bid not found');
    if (!bid.isAccepted) throw Exception('Bid must be accepted first');

    final paidBid = bid.copyWith(
      depositPaymentId: paymentId,
      depositPaidAt: DateTime.now(),
      depositPaymentMethod: paymentMethod,
    );

    await saveBid(paidBid);
    return paidBid;
  }

  /// Convert accepted bid to job
  Future<Bid> convertToJob(String bidId, String jobId) async {
    final bid = await getBid(bidId);
    if (bid == null) throw Exception('Bid not found');
    if (!bid.canConvert) throw Exception('Bid cannot be converted');

    final convertedBid = bid.copyWith(
      status: BidStatus.converted,
      convertedJobId: jobId,
      convertedAt: DateTime.now(),
    );

    await saveBid(convertedBid);
    return convertedBid;
  }

  // ==================== TEMPLATES ====================

  /// Get all templates for a trade
  Future<List<BidTemplate>> getTemplatesForTrade(String tradeType) async {
    final box = await _getTemplateBox();
    final templates = <BidTemplate>[];

    for (final key in box.keys) {
      final json = box.get(key);
      if (json != null) {
        try {
          final template = BidTemplate.fromMap(jsonDecode(json));
          if (template.tradeType == tradeType && template.isActive) {
            templates.add(template);
          }
        } catch (_) {}
      }
    }

    // Sort by use count (most popular first)
    templates.sort((a, b) => b.useCount.compareTo(a.useCount));
    return templates;
  }

  /// Get a template by ID
  Future<BidTemplate?> getTemplate(String id) async {
    final box = await _getTemplateBox();
    final json = box.get(id);
    if (json == null) return null;
    return BidTemplate.fromMap(jsonDecode(json));
  }

  /// Save template
  Future<void> saveTemplate(BidTemplate template) async {
    final box = await _getTemplateBox();
    await box.put(template.id, jsonEncode(template.toMap()));
  }

  /// Delete template
  Future<void> deleteTemplate(String id) async {
    final box = await _getTemplateBox();
    await box.delete(id);
  }

  /// Increment template use count
  Future<void> incrementTemplateUseCount(String templateId) async {
    final template = await getTemplate(templateId);
    if (template != null) {
      await saveTemplate(template.copyWith(
        useCount: template.useCount + 1,
      ));
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Mark a bid as needing sync
  Future<void> _markForSync(String bidId) async {
    final metaBox = await _getSyncMetaBox();
    await metaBox.put('pending_$bidId', DateTime.now().toIso8601String());
  }

  /// Mark a bid deletion for sync
  Future<void> _markDeletionForSync(String bidId) async {
    final metaBox = await _getSyncMetaBox();
    await metaBox.put('delete_$bidId', DateTime.now().toIso8601String());
    await metaBox.delete('pending_$bidId');
  }

  /// Try to sync a single bid immediately
  Future<void> _trySyncBid(Bid bid) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) return;

      // Check if this is a new bid or update
      final existing = await _cloudService.getBid(bid.id);
      if (existing == null) {
        await _cloudService.createBid(bid);
      } else {
        await _cloudService.updateBid(bid);
      }

      // Clear sync marker and update local
      final metaBox = await _getSyncMetaBox();
      await metaBox.delete('pending_${bid.id}');

      // Mark as synced locally
      final box = await _getBox();
      final syncedBid = bid.copyWith(syncedToCloud: true);
      await box.put(bid.id, jsonEncode(syncedBid.toMap()));
    } catch (_) {
      // Sync failed - will retry later
    }
  }

  /// Full sync with cloud
  Future<void> syncWithCloud() async {
    if (!_isLoggedIn) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      throw Exception('No internet connection');
    }

    final metaBox = await _getSyncMetaBox();
    final localBox = await _getBox();

    // 1. Process pending deletions
    final deleteKeys = metaBox.keys.where((k) => k.toString().startsWith('delete_'));
    for (final key in deleteKeys) {
      final bidId = key.toString().replaceFirst('delete_', '');
      try {
        await _cloudService.deleteBid(bidId);
        await metaBox.delete(key);
      } catch (_) {}
    }

    // 2. Push pending local changes to cloud
    final pendingKeys = metaBox.keys.where((k) => k.toString().startsWith('pending_'));
    for (final key in pendingKeys) {
      final bidId = key.toString().replaceFirst('pending_', '');
      final localJson = localBox.get(bidId);
      if (localJson != null) {
        try {
          final bid = Bid.fromMap(jsonDecode(localJson));
          final existing = await _cloudService.getBid(bidId);
          if (existing == null) {
            await _cloudService.createBid(bid);
          } else {
            await _cloudService.updateBid(bid);
          }
          await metaBox.delete(key);

          // Mark as synced
          final syncedBid = bid.copyWith(syncedToCloud: true);
          await localBox.put(bidId, jsonEncode(syncedBid.toMap()));
        } catch (_) {}
      }
    }

    // 3. Pull cloud changes
    final lastSyncStr = metaBox.get('lastSync');
    final lastSync = lastSyncStr != null
        ? DateTime.parse(lastSyncStr)
        : DateTime.fromMillisecondsSinceEpoch(0);

    final cloudBids = await _cloudService.getBidsUpdatedSince(lastSync);

    for (final cloudBid in cloudBids) {
      final localJson = localBox.get(cloudBid.id);
      if (localJson != null) {
        // Conflict resolution: cloud wins if updated more recently
        final localBid = Bid.fromMap(jsonDecode(localJson));
        if (cloudBid.updatedAt.isAfter(localBid.updatedAt)) {
          await localBox.put(cloudBid.id, jsonEncode(cloudBid.toMap()));
        }
      } else {
        // New from cloud
        await localBox.put(cloudBid.id, jsonEncode(cloudBid.toMap()));
      }
    }

    // 4. Update last sync time
    await metaBox.put('lastSync', DateTime.now().toIso8601String());
  }

  /// Get count of pending sync items
  Future<int> getPendingSyncCount() async {
    final metaBox = await _getSyncMetaBox();
    return metaBox.keys
        .where((k) => k.toString().startsWith('pending_') || k.toString().startsWith('delete_'))
        .length;
  }

  // ==================== UTILITY ====================

  /// Check for expired bids and update status
  Future<void> checkExpiredBids() async {
    final bids = await getAllBids();
    final now = DateTime.now();

    for (final bid in bids) {
      if (bid.isPending && bid.validUntil != null && now.isAfter(bid.validUntil!)) {
        await saveBid(bid.copyWith(status: BidStatus.expired));
      }
    }
  }

  /// Duplicate a bid (for resending declined bids)
  Future<Bid> duplicateBid(String bidId) async {
    final original = await getBid(bidId);
    if (original == null) throw Exception('Bid not found');

    final newBidNumber = await generateBidNumber();
    final now = DateTime.now();

    return Bid(
      id: generateId(),
      companyId: original.companyId,
      createdByUserId: _userId ?? original.createdByUserId,
      bidNumber: newBidNumber,
      tradeType: original.tradeType,
      customerId: original.customerId,
      customerName: original.customerName,
      customerEmail: original.customerEmail,
      customerPhone: original.customerPhone,
      customerAddress: original.customerAddress,
      customerCity: original.customerCity,
      customerState: original.customerState,
      customerZipCode: original.customerZipCode,
      projectName: original.projectName,
      projectDescription: original.projectDescription,
      scopeOfWork: original.scopeOfWork,
      options: original.options,
      addOns: original.addOns.map((a) => a.copyWith(isSelected: false)).toList(),
      photos: original.photos,
      calculationIds: original.calculationIds,
      taxRate: original.taxRate,
      depositPercent: original.depositPercent,
      companyName: original.companyName,
      companyLogoUrl: original.companyLogoUrl,
      companyAddress: original.companyAddress,
      companyPhone: original.companyPhone,
      companyEmail: original.companyEmail,
      companyLicense: original.companyLicense,
      terms: original.terms,
      validUntil: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );
  }
}
