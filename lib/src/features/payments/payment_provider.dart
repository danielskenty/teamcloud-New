import '../pos/models/cart_item.dart';

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? message;

  PaymentResult({required this.success, this.transactionId, this.message});
}

abstract class PaymentProvider {
  /// Process a payment of [amount] in smallest currency unit (e.g., cents)
  Future<PaymentResult> processPayment({
    required int amountCents,
    required String currency,
    required String reference,
    List<CartItem> items = const [],
    Map<String, dynamic>? metadata,
  });
}

// Default/mock provider used in development
class MockPaymentProvider implements PaymentProvider {
  @override
  Future<PaymentResult> processPayment({
    required int amountCents,
    required String currency,
    required String reference,
    List<CartItem> items = const [],
    Map<String, dynamic>? metadata,
  }) async {
    // Simulate network latency
    await Future.delayed(const Duration(seconds: 1));
    return PaymentResult(
      success: true,
      transactionId: 'mock_txn_\$reference',
      message: 'Mock payment successful',
    );
  }
}
