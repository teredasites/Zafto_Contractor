// ZAFTO Price Book Provider
// Created: DEPTH29 — Estimate Engine Overhaul
//
// Riverpod providers for company price book (S130 Owner Directive).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/price_book_item.dart';
import '../repositories/price_book_repository.dart';

// ════════════════════════════════════════════════════════════════
// REPOSITORY
// ════════════════════════════════════════════════════════════════

final priceBookRepoProvider = Provider<PriceBookRepository>((ref) {
  return PriceBookRepository();
});

// ════════════════════════════════════════════════════════════════
// ALL PRICE BOOK ITEMS
// ════════════════════════════════════════════════════════════════

final priceBookItemsProvider =
    FutureProvider.autoDispose<List<PriceBookItem>>((ref) async {
  final repo = ref.read(priceBookRepoProvider);
  return repo.getItems();
});

// ════════════════════════════════════════════════════════════════
// PRICE BOOK BY TRADE
// ════════════════════════════════════════════════════════════════

final priceBookByTradeProvider = FutureProvider.autoDispose
    .family<List<PriceBookItem>, String>((ref, trade) async {
  final repo = ref.read(priceBookRepoProvider);
  return repo.getByTrade(trade);
});

// ════════════════════════════════════════════════════════════════
// PRICE BOOK SEARCH
// ════════════════════════════════════════════════════════════════

final priceBookSearchProvider = FutureProvider.autoDispose
    .family<List<PriceBookItem>, String>((ref, query) async {
  final repo = ref.read(priceBookRepoProvider);
  return repo.search(query);
});
