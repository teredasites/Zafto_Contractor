// ZAFTO Bid Service — Supabase Backend
// Rewritten: Sprint B1d (Session 42)
//
// Replaces Hive + Firestore sync with direct Supabase queries.
// Same provider names so all consuming screens keep working.

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bid.dart';
import '../repositories/bid_repository.dart';
import 'auth_service.dart';

// ============================================================
// PROVIDERS
// ============================================================

final bidRepositoryProvider = Provider<BidRepository>((ref) {
  return BidRepository();
});

final bidServiceProvider = Provider<BidService>((ref) {
  final repo = ref.watch(bidRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return BidService(repo, authState);
});

final bidsProvider =
    StateNotifierProvider<BidsNotifier, AsyncValue<List<Bid>>>(
        (ref) {
  final service = ref.watch(bidServiceProvider);
  return BidsNotifier(service);
});

final draftBidsProvider = Provider<List<Bid>>((ref) {
  final bids = ref.watch(bidsProvider);
  return bids.maybeWhen(
    data: (list) =>
        list.where((b) => b.status == BidStatus.draft).toList(),
    orElse: () => [],
  );
});

final pendingBidsProvider = Provider<List<Bid>>((ref) {
  final bids = ref.watch(bidsProvider);
  return bids.maybeWhen(
    data: (list) => list.where((b) => b.isPending).toList(),
    orElse: () => [],
  );
});

final acceptedBidsProvider = Provider<List<Bid>>((ref) {
  final bids = ref.watch(bidsProvider);
  return bids.maybeWhen(
    data: (list) => list.where((b) => b.isAccepted).toList(),
    orElse: () => [],
  );
});

final bidStatsProvider = Provider<BidStats>((ref) {
  final bids = ref.watch(bidsProvider);
  return bids.maybeWhen(
    data: (list) {
      final drafts =
          list.where((b) => b.status == BidStatus.draft).length;
      final sent = list
          .where((b) =>
              b.status == BidStatus.sent ||
              b.status == BidStatus.viewed)
          .length;
      final accepted = list
          .where((b) =>
              b.status == BidStatus.accepted ||
              b.status == BidStatus.converted)
          .length;
      final rejected = list
          .where((b) => b.status == BidStatus.rejected)
          .length;

      final acceptedBids = list.where((b) =>
          b.status == BidStatus.accepted ||
          b.status == BidStatus.converted);
      final totalValue = acceptedBids.fold<double>(
          0.0, (sum, b) => sum + b.total);

      final pendingBids = list.where((b) =>
          b.status == BidStatus.sent ||
          b.status == BidStatus.viewed);
      final pendingValue = pendingBids.fold<double>(
          0.0, (sum, b) => sum + b.total);

      final decisions = accepted + rejected;
      final winRate =
          decisions > 0 ? (accepted / decisions * 100) : 0.0;

      return BidStats(
        totalBids: list.length,
        draftBids: drafts,
        sentBids: sent,
        acceptedBids: accepted,
        declinedBids: rejected,
        totalValue: totalValue,
        pendingValue: pendingValue,
        winRate: winRate,
      );
    },
    orElse: () => BidStats.empty(),
  );
});

final bidCountProvider = Provider<int>((ref) {
  final stats = ref.watch(bidStatsProvider);
  return stats.totalBids;
});

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

  String get totalValueDisplay =>
      '\$${totalValue.toStringAsFixed(2)}';
  String get pendingValueDisplay =>
      '\$${pendingValue.toStringAsFixed(2)}';
  String get winRateDisplay =>
      '${winRate.toStringAsFixed(1)}%';
}

// ============================================================
// BIDS NOTIFIER
// ============================================================

class BidsNotifier extends StateNotifier<AsyncValue<List<Bid>>> {
  final BidService _service;

  BidsNotifier(this._service)
      : super(const AsyncValue.loading()) {
    loadBids();
  }

  Future<void> loadBids() async {
    state = const AsyncValue.loading();
    try {
      final bids = await _service.getAllBids();
      state = AsyncValue.data(bids);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBid(Bid bid) async {
    try {
      await _service.createBid(bid);
      await loadBids();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateBid(Bid bid) async {
    try {
      await _service.updateBid(bid);
      await loadBids();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteBid(String id) async {
    try {
      await _service.deleteBid(id);
      await loadBids();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<Bid> search(String query) {
    return state.maybeWhen(
      data: (list) {
        final q = query.toLowerCase();
        return list
            .where((b) =>
                b.bidNumber.toLowerCase().contains(q) ||
                b.customerName.toLowerCase().contains(q) ||
                b.displayTitle.toLowerCase().contains(q) ||
                (b.notes?.toLowerCase().contains(q) ?? false))
            .toList();
      },
      orElse: () => [],
    );
  }
}

// ============================================================
// BID SERVICE (business logic)
// ============================================================

class BidService {
  final BidRepository _repo;
  final AuthState _authState;

  BidService(this._repo, this._authState);

  Future<List<Bid>> getAllBids() => _repo.getBids();

  Future<Bid?> getBid(String id) => _repo.getBid(id);

  Future<List<Bid>> getBidsByStatus(BidStatus status) =>
      _repo.getBidsByStatus(status);

  Future<List<Bid>> getBidsForCustomer(String customerId) =>
      _repo.getBidsByCustomer(customerId);

  Future<Bid> createBid(Bid bid) {
    final enriched = bid.copyWith(
      companyId: _authState.companyId ?? '',
      createdByUserId: _authState.user?.uid ?? '',
    );
    return _repo.createBid(enriched);
  }

  Future<Bid> updateBid(Bid bid) => _repo.updateBid(bid.id, bid);

  Future<void> deleteBid(String id) => _repo.deleteBid(id);

  Future<List<Bid>> searchBids(String query) =>
      _repo.searchBids(query);

  Future<String> generateBidNumber() => _repo.nextBidNumber();

  String generateAccessToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
            32, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  // Backward compat
  String generateId() =>
      'bid_${DateTime.now().millisecondsSinceEpoch}';

  // Kept for screens that call saveBid
  Future<Bid> saveBid(Bid bid) async {
    if (bid.id.isEmpty) {
      return createBid(bid);
    } else {
      return updateBid(bid);
    }
  }

  // ==================== BID OPERATIONS ====================

  Future<Bid> sendBid(Bid bid) async {
    if (bid.status != BidStatus.draft) {
      throw Exception('Can only send draft bids');
    }
    if (bid.options.isEmpty) {
      throw Exception('Bid must have at least one option');
    }
    final sentBid = bid.copyWith(
      status: BidStatus.sent,
      sentAt: DateTime.now(),
    );
    return saveBid(sentBid);
  }

  Future<Bid> markBidViewed(String bidId) async {
    final bid = await getBid(bidId);
    if (bid == null) throw Exception('Bid not found');
    if (bid.viewedAt != null) return bid;
    final viewedBid = bid.copyWith(
      status: BidStatus.viewed,
      viewedAt: DateTime.now(),
    );
    return saveBid(viewedBid);
  }

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

    final updatedAddOns = bid.addOns.map((addon) {
      final isSelected =
          selectedAddOnIds?.contains(addon.id) ?? false;
      return addon.copyWith(isSelected: isSelected);
    }).toList();

    var acceptedBid = bid.copyWith(
      status: BidStatus.accepted,
      selectedOptionId: selectedOptionId,
      addOns: updatedAddOns,
      signatureData: signatureData,
      signedByName: signedByName,
      signedAt: DateTime.now(),
      acceptedAt: DateTime.now(),
    );
    acceptedBid = acceptedBid.recalculate();
    return saveBid(acceptedBid);
  }

  Future<Bid> rejectBid(String bidId, {String? reason}) async {
    final bid = await getBid(bidId);
    if (bid == null) throw Exception('Bid not found');
    if (!bid.isPending) throw Exception('Bid is not pending');

    final rejectedBid = bid.copyWith(
      status: BidStatus.rejected,
      rejectionReason: reason,
      rejectedAt: DateTime.now(),
    );
    return saveBid(rejectedBid);
  }

  // Backward compat for screens that called declineBid
  Future<Bid> declineBid(String bidId, {String? reason}) =>
      rejectBid(bidId, reason: reason);

  Future<Bid> convertToJob(String bidId, String jobId) async {
    final bid = await getBid(bidId);
    if (bid == null) throw Exception('Bid not found');
    if (!bid.canConvert) throw Exception('Bid cannot be converted');

    final convertedBid = bid.copyWith(
      status: BidStatus.converted,
      jobId: jobId,
    );
    return saveBid(convertedBid);
  }

  Future<Bid> duplicateBid(String bidId) async {
    final original = await getBid(bidId);
    if (original == null) throw Exception('Bid not found');

    final newBidNumber = await generateBidNumber();
    final now = DateTime.now();

    return Bid(
      companyId: _authState.companyId ?? original.companyId,
      createdByUserId:
          _authState.user?.uid ?? original.createdByUserId,
      bidNumber: newBidNumber,
      title: original.title,
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
      addOns: original.addOns
          .map((a) => a.copyWith(isSelected: false))
          .toList(),
      photos: original.photos,
      taxRate: original.taxRate,
      depositPercent: original.depositPercent,
      terms: original.terms,
      validUntil: now.add(const Duration(days: 30)),
      createdAt: now,
      updatedAt: now,
    );
  }
}
