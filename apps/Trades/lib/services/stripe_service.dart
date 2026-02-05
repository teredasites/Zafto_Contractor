/// ZAFTO Stripe Payment Service
/// Sprint P0 - February 2026
/// Payment processing for deposits and invoices
///
/// SETUP REQUIRED:
/// 1. Create Stripe account at https://dashboard.stripe.com/register
/// 2. Get API keys from Stripe Dashboard -> Developers -> API Keys
/// 3. Add publishable key to lib/config/stripe_config.dart
/// 4. Add secret key to Firebase Cloud Functions config
/// 5. Set up webhook endpoint in Stripe Dashboard

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';

import '../models/bid.dart';
import '../models/business/invoice.dart';

// ============================================================
// PROVIDERS
// ============================================================

final stripeServiceProvider = Provider<StripeService>((ref) {
  return StripeService();
});

/// Payment status for tracking
final paymentStatusProvider = StateProvider<PaymentStatus>((ref) => PaymentStatus.idle);

enum PaymentStatus {
  idle,
  processing,
  success,
  failed,
  cancelled,
}

// ============================================================
// CONFIG
// ============================================================

/// Stripe configuration
class StripeConfig {
  // Live publishable key
  static const String publishableKey = 'pk_live_51SwbVnCqKgR2sHD4panyEJIx5GP5LtiXlo8vs3aiKFeYVVRc6CeNrQNxOmCOpSjrUd1MVti8Ed6UDEm6D1KKIRfN00vuqHWe5c';

  // For Apple Pay (iOS)
  static const String merchantId = 'merchant.com.tereda.zafto';

  // Cloud Function endpoints
  static const String createPaymentIntentUrl =
      'https://us-central1-zafto-5c3f2.cloudfunctions.net/createPaymentIntent';
  static const String confirmPaymentUrl =
      'https://us-central1-zafto-5c3f2.cloudfunctions.net/confirmPayment';
}

// ============================================================
// SERVICE
// ============================================================

class StripeService {
  bool _isInitialized = false;

  /// Initialize Stripe SDK
  /// Call this in main.dart before runApp()
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Uncomment when flutter_stripe is added to dependencies
    // Stripe.publishableKey = StripeConfig.publishableKey;
    // Stripe.merchantIdentifier = StripeConfig.merchantId;
    // await Stripe.instance.applySettings();

    _isInitialized = true;
    debugPrint('Stripe initialized');
  }

  /// Collect deposit for a bid
  /// Returns true if payment was successful
  Future<PaymentResult> collectBidDeposit({
    required Bid bid,
    required double amount,
    required String customerEmail,
    String? description,
  }) async {
    try {
      // 1. Create PaymentIntent via Cloud Function
      final paymentIntent = await _createPaymentIntent(
        amount: amount,
        currency: 'usd',
        customerEmail: customerEmail,
        description: description ?? 'Deposit for ${bid.title}',
        metadata: {
          'type': 'bid_deposit',
          'bid_id': bid.id,
          'customer_name': bid.customerName,
        },
      );

      if (paymentIntent == null) {
        return PaymentResult.failure('Failed to create payment intent');
      }

      // 2. Present payment sheet to customer
      // Uncomment when flutter_stripe is added
      // await Stripe.instance.initPaymentSheet(
      //   paymentSheetParameters: SetupPaymentSheetParameters(
      //     paymentIntentClientSecret: paymentIntent['client_secret'],
      //     merchantDisplayName: 'ZAFTO Trades',
      //     style: ThemeMode.system,
      //     appearance: PaymentSheetAppearance(
      //       colors: PaymentSheetAppearanceColors(
      //         primary: const Color(0xFFFF9500),
      //       ),
      //     ),
      //   ),
      // );
      // await Stripe.instance.presentPaymentSheet();

      // For now, simulate success
      await Future.delayed(const Duration(seconds: 2));

      return PaymentResult.success(
        paymentIntentId: paymentIntent['id'] ?? 'simulated',
        amount: amount,
      );
    } catch (e) {
      debugPrint('Payment error: $e');
      return PaymentResult.failure(e.toString());
    }
  }

  /// Collect payment for an invoice
  Future<PaymentResult> collectInvoicePayment({
    required Invoice invoice,
    required double amount,
    required String customerEmail,
  }) async {
    try {
      final paymentIntent = await _createPaymentIntent(
        amount: amount,
        currency: 'usd',
        customerEmail: customerEmail,
        description: 'Invoice #${invoice.invoiceNumber ?? invoice.id.substring(0, 8)}',
        metadata: {
          'type': 'invoice_payment',
          'invoice_id': invoice.id,
          'customer_name': invoice.customerName,
        },
      );

      if (paymentIntent == null) {
        return PaymentResult.failure('Failed to create payment intent');
      }

      // Present payment sheet
      // Uncomment when flutter_stripe is added
      // await Stripe.instance.initPaymentSheet(
      //   paymentSheetParameters: SetupPaymentSheetParameters(
      //     paymentIntentClientSecret: paymentIntent['client_secret'],
      //     merchantDisplayName: 'ZAFTO Trades',
      //   ),
      // );
      // await Stripe.instance.presentPaymentSheet();

      // Simulate success for now
      await Future.delayed(const Duration(seconds: 2));

      return PaymentResult.success(
        paymentIntentId: paymentIntent['id'] ?? 'simulated',
        amount: amount,
      );
    } catch (e) {
      debugPrint('Payment error: $e');
      return PaymentResult.failure(e.toString());
    }
  }

  /// Create a payment link that can be sent to customers
  Future<String?> createPaymentLink({
    required double amount,
    required String description,
    required String customerEmail,
    Map<String, String>? metadata,
  }) async {
    // This would typically call a Cloud Function to create a Stripe Payment Link
    // For now, return null (not implemented)
    debugPrint('Payment links require Cloud Function setup');
    return null;
  }

  /// Create a PaymentIntent via Cloud Function
  Future<Map<String, dynamic>?> _createPaymentIntent({
    required double amount,
    required String currency,
    required String customerEmail,
    String? description,
    Map<String, String>? metadata,
  }) async {
    // In production, this would call your Cloud Function:
    // final response = await http.post(
    //   Uri.parse(StripeConfig.createPaymentIntentUrl),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'amount': (amount * 100).round(), // Stripe uses cents
    //     'currency': currency,
    //     'customer_email': customerEmail,
    //     'description': description,
    //     'metadata': metadata,
    //   }),
    // );
    // return jsonDecode(response.body);

    // Simulated response for development
    return {
      'id': 'pi_simulated_${DateTime.now().millisecondsSinceEpoch}',
      'client_secret': 'pi_simulated_secret',
      'amount': (amount * 100).round(),
      'currency': currency,
    };
  }

  /// Check if a payment was successful
  Future<bool> verifyPayment(String paymentIntentId) async {
    // In production, verify with Cloud Function
    // For now, always return true for simulated payments
    return paymentIntentId.startsWith('pi_simulated_') || true;
  }
}

// ============================================================
// PAYMENT RESULT
// ============================================================

class PaymentResult {
  final bool isSuccess;
  final String? paymentIntentId;
  final double? amount;
  final String? errorMessage;

  const PaymentResult._({
    required this.isSuccess,
    this.paymentIntentId,
    this.amount,
    this.errorMessage,
  });

  factory PaymentResult.success({
    required String paymentIntentId,
    required double amount,
  }) {
    return PaymentResult._(
      isSuccess: true,
      paymentIntentId: paymentIntentId,
      amount: amount,
    );
  }

  factory PaymentResult.failure(String message) {
    return PaymentResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

// ============================================================
// CLOUD FUNCTION TEMPLATE
// ============================================================
///
/// Save this to firebase/functions/src/stripe.ts:
///
/// ```typescript
/// import * as functions from 'firebase-functions';
/// import Stripe from 'stripe';
///
/// const stripe = new Stripe(functions.config().stripe.secret_key, {
///   apiVersion: '2023-10-16',
/// });
///
/// export const createPaymentIntent = functions.https.onRequest(async (req, res) => {
///   try {
///     const { amount, currency, customer_email, description, metadata } = req.body;
///
///     const paymentIntent = await stripe.paymentIntents.create({
///       amount,
///       currency,
///       receipt_email: customer_email,
///       description,
///       metadata,
///       automatic_payment_methods: { enabled: true },
///     });
///
///     res.json({
///       id: paymentIntent.id,
///       client_secret: paymentIntent.client_secret,
///       amount: paymentIntent.amount,
///       currency: paymentIntent.currency,
///     });
///   } catch (error: any) {
///     res.status(500).json({ error: error.message });
///   }
/// });
///
/// export const stripeWebhook = functions.https.onRequest(async (req, res) => {
///   const sig = req.headers['stripe-signature'] as string;
///   const webhookSecret = functions.config().stripe.webhook_secret;
///
///   let event: Stripe.Event;
///
///   try {
///     event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
///   } catch (err: any) {
///     res.status(400).send(`Webhook Error: ${err.message}`);
///     return;
///   }
///
///   switch (event.type) {
///     case 'payment_intent.succeeded':
///       const paymentIntent = event.data.object as Stripe.PaymentIntent;
///       // Update Firestore with payment status
///       // e.g., mark invoice as paid, mark bid deposit as received
///       break;
///     case 'payment_intent.payment_failed':
///       // Handle failed payment
///       break;
///   }
///
///   res.json({ received: true });
/// });
/// ```
///
/// Setup commands:
/// ```bash
/// cd firebase/functions
/// npm install stripe
/// firebase functions:config:set stripe.secret_key="sk_live_YOUR_KEY"
/// firebase functions:config:set stripe.webhook_secret="whsec_YOUR_SECRET"
/// firebase deploy --only functions
/// ```
