// ZAFTO Bid Repository
// Created: Sprint B1d (Session 42)
//
// Supabase CRUD for bids table.
// RLS handles company scoping automatically.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/bid.dart';

class BidRepository {
  // ============================================================
  // READ
  // ============================================================

  Future<List<Bid>> getBids() async {
    try {
      final response = await supabase
          .from('bids')
          .select()
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false);
      return (response as List)
          .map((row) => Bid.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch bids: $e', cause: e);
    }
  }

  Future<Bid?> getBid(String id) async {
    try {
      final response = await supabase
          .from('bids')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Bid.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to fetch bid: $e', cause: e);
    }
  }

  Future<List<Bid>> getBidsByStatus(BidStatus status) async {
    try {
      final response = await supabase
          .from('bids')
          .select()
          .eq('status', status.dbValue)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => Bid.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
          'Failed to fetch bids by status: $e', cause: e);
    }
  }

  Future<List<Bid>> getBidsByCustomer(String customerId) async {
    try {
      final response = await supabase
          .from('bids')
          .select()
          .eq('customer_id', customerId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => Bid.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError(
          'Failed to fetch bids for customer: $e', cause: e);
    }
  }

  Future<List<Bid>> searchBids(String query) async {
    try {
      final q = '%$query%';
      final response = await supabase
          .from('bids')
          .select()
          .or('bid_number.ilike.$q,customer_name.ilike.$q,title.ilike.$q,notes.ilike.$q')
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false);
      return (response as List)
          .map((row) => Bid.fromJson(row))
          .toList();
    } catch (e) {
      throw DatabaseError('Failed to search bids: $e', cause: e);
    }
  }

  // ============================================================
  // WRITE
  // ============================================================

  Future<Bid> createBid(Bid bid) async {
    try {
      final response = await supabase
          .from('bids')
          .insert(bid.toInsertJson())
          .select()
          .single();
      return Bid.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create bid: $e',
        userMessage: 'Could not create bid. Please try again.',
        cause: e,
      );
    }
  }

  Future<Bid> updateBid(String id, Bid bid) async {
    try {
      final response = await supabase
          .from('bids')
          .update(bid.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return Bid.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update bid: $e',
        userMessage: 'Could not update bid. Please try again.',
        cause: e,
      );
    }
  }

  Future<Bid> updateBidStatus(String id, BidStatus status) async {
    try {
      final data = <String, dynamic>{'status': status.dbValue};
      final now = DateTime.now().toUtc().toIso8601String();
      if (status == BidStatus.sent) {
        data['sent_at'] = now;
      } else if (status == BidStatus.accepted) {
        data['accepted_at'] = now;
      } else if (status == BidStatus.rejected) {
        data['rejected_at'] = now;
      }
      final response = await supabase
          .from('bids')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Bid.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update bid status: $e',
        userMessage:
            'Could not update bid status. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> deleteBid(String id) async {
    try {
      await supabase
          .from('bids')
          .update(
              {'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete bid: $e',
        userMessage: 'Could not delete bid. Please try again.',
        cause: e,
      );
    }
  }

  // ============================================================
  // SEQUENCE
  // ============================================================

  Future<String> nextBidNumber() async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final prefix = 'BID-$dateStr-';
      final response = await supabase
          .from('bids')
          .select('bid_number')
          .like('bid_number', '$prefix%')
          .order('bid_number', ascending: false)
          .limit(1)
          .maybeSingle();

      int next = 1;
      if (response != null) {
        final lastNumber = response['bid_number'] as String;
        final seq = int.tryParse(lastNumber.split('-').last) ?? 0;
        next = seq + 1;
      }
      return '$prefix${next.toString().padLeft(3, '0')}';
    } catch (e) {
      final now = DateTime.now();
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final ms = DateTime.now().millisecondsSinceEpoch % 1000;
      return 'BID-$dateStr-${ms.toString().padLeft(3, '0')}';
    }
  }
}
