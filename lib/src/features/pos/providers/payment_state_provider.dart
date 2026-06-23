import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../payments/payment_provider.dart';
import '../../payments/nomba/nomba_payment_provider.dart';

final paymentMethodProvider = StateProvider<String>((ref) => 'cash');

final paymentProvider = Provider<PaymentProvider>((ref) {
  final method = ref.watch(paymentMethodProvider);
  if (method == 'nomba') {
    // Replace with your backend endpoint that performs Nomba API calls.
    return NombaPaymentProvider(backendEndpoint: 'https://your-backend.example.com');
  }
  return MockPaymentProvider();
});
