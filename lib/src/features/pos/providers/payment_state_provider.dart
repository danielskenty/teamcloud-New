import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/backend_config.dart';
import '../../payments/payment_provider.dart';
import '../../payments/nomba/nomba_payment_provider.dart';
import '../services/sale_finalization_service.dart';

final paymentMethodProvider = StateProvider<String>((ref) => 'cash');

final paymentProvider = Provider<PaymentProvider>((ref) {
  final method = ref.watch(paymentMethodProvider);
  if (method == 'nomba') {
    return NombaPaymentProvider(backendEndpoint: BackendConfig.functionsUrl);
  }
  return MockPaymentProvider();
});

final saleFinalizationServiceProvider = Provider<SaleFinalizationService>((
  ref,
) {
  return SaleFinalizationService(backendEndpoint: BackendConfig.functionsUrl);
});
