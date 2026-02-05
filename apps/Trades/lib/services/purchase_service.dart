/// Purchase Service - In-App Purchases for AI scan credits
/// 
/// Manages:
/// - Credit packages (5, 20, 50 scans)
/// - Purchase flow
/// - Restore purchases
/// - Receipt validation (server-side)
/// 
/// Products:
/// - zafto_credits_5: 5 scans for $1.99
/// - zafto_credits_20: 20 scans for $4.99
/// - zafto_credits_50: 50 scans for $9.99

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'ai_service.dart';
// Conditional import for Platform
import 'platform_stub.dart' if (dart.library.io) 'dart:io';

/// Credit package definition
class CreditPackage {
  final String productId;
  final int credits;
  final String title;
  final String description;
  final String? price; // Loaded from store
  
  const CreditPackage({
    required this.productId,
    required this.credits,
    required this.title,
    required this.description,
    this.price,
  });
  
  CreditPackage copyWithPrice(String price) => CreditPackage(
    productId: productId,
    credits: credits,
    title: title,
    description: description,
    price: price,
  );
}

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  bool _isAvailable = false;
  bool _initialized = false;
  List<ProductDetails> _products = [];
  
  // Callbacks for UI updates
  Function(String message)? onError;
  Function(int credits)? onPurchaseComplete;
  Function()? onPurchasePending;
  Function()? onPurchaseRestored;

  // Product IDs - must match App Store Connect / Play Console
  static const Set<String> _productIds = {
    'zafto_credits_5',
    'zafto_credits_20', 
    'zafto_credits_50',
  };

  // Package definitions
  static const List<CreditPackage> packages = [
    CreditPackage(
      productId: 'zafto_credits_5',
      credits: 5,
      title: '5 Scans',
      description: 'Best for trying it out',
    ),
    CreditPackage(
      productId: 'zafto_credits_20',
      credits: 20,
      title: '20 Scans',
      description: 'Most popular',
    ),
    CreditPackage(
      productId: 'zafto_credits_50',
      credits: 50,
      title: '50 Scans',
      description: 'Best value - save 17%',
    ),
  ];

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;

  /// Get packages with real prices from store
  List<CreditPackage> get packagesWithPrices {
    return packages.map((pkg) {
      final product = _products.firstWhere(
        (p) => p.id == pkg.productId,
        orElse: () => throw StateError('Product not found'),
      );
      return pkg.copyWithPrice(product.price);
    }).toList();
  }

  /// Initialize IAP and load products
  Future<void> initialize() async {
    if (_initialized) return;
    
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      debugPrint('IAP not available on this device');
      _initialized = true;
      return;
    }

    // Listen for purchase updates
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('Purchase stream error: $error'),
    );

    // Load products from store
    await _loadProducts();
    
    _initialized = true;
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(_productIds);
    
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }
    
    _products = response.productDetails;
    debugPrint('Loaded ${_products.length} products');
  }

  /// Purchase a credit package
  Future<bool> purchase(String productId) async {
    if (!_isAvailable) {
      onError?.call('Purchases not available on this device');
      return false;
    }

    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw StateError('Product $productId not found'),
    );

    final purchaseParam = PurchaseParam(productDetails: product);
    
    try {
      // Consumable purchase (can buy multiple times)
      return await _iap.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Purchase error: $e');
      onError?.call('Purchase failed. Please try again.');
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      onError?.call('Purchases not available');
      return;
    }
    
    await _iap.restorePurchases();
  }

  /// Handle purchase updates from the store
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        debugPrint('Purchase pending: ${purchase.productID}');
        onPurchasePending?.call();
        break;
        
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        debugPrint('Purchase complete: ${purchase.productID}');
        
        // Verify purchase (in production, verify server-side)
        final valid = await _verifyPurchase(purchase);
        
        if (valid) {
          // Add credits
          final credits = _getCreditsForProduct(purchase.productID);
          await aiService.addCredits(credits);
          
          // Log purchase
          await _logPurchase(purchase, credits);
          
          if (purchase.status == PurchaseStatus.purchased) {
            onPurchaseComplete?.call(credits);
          } else {
            onPurchaseRestored?.call();
          }
        } else {
          onError?.call('Purchase verification failed');
        }
        
        // Complete the purchase
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;
        
      case PurchaseStatus.error:
        debugPrint('Purchase error: ${purchase.error}');
        onError?.call(purchase.error?.message ?? 'Purchase failed');
        
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;
        
      case PurchaseStatus.canceled:
        debugPrint('Purchase canceled');
        // User canceled - no action needed
        break;
    }
  }

  /// Verify purchase receipt
  /// In production, send to server for validation
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // TODO: Server-side verification
    // For now, trust the client (acceptable for low-value consumables)
    
    if (Platform.isIOS) {
      // iOS: Verify with App Store
      // final receiptData = purchase.verificationData.localVerificationData;
      // Send to server -> server calls Apple's verifyReceipt API
    } else if (Platform.isAndroid) {
      // Android: Verify with Google Play
      // final purchaseToken = purchase.verificationData.serverVerificationData;
      // Send to server -> server calls Google Play Developer API
    }
    
    return true; // Trust client for MVP
  }

  int _getCreditsForProduct(String productId) {
    final package = packages.firstWhere(
      (p) => p.productId == productId,
      orElse: () => throw StateError('Unknown product: $productId'),
    );
    return package.credits;
  }

  Future<void> _logPurchase(PurchaseDetails purchase, int credits) async {
    final box = Hive.box('app_state');
    final history = List<Map<String, dynamic>>.from(
      box.get('purchase_history', defaultValue: []),
    );
    
    history.add({
      'productId': purchase.productID,
      'credits': credits,
      'timestamp': DateTime.now().toIso8601String(),
      'transactionId': purchase.purchaseID,
    });
    
    await box.put('purchase_history', history);
  }

  void dispose() {
    _subscription?.cancel();
  }
}

// Global instance
final purchaseService = PurchaseService();
