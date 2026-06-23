import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';

final customerRepositoryProvider = Provider((ref) {
  return CustomerRepository();
});

final customersStreamProvider = StreamProvider.family<List<Customer>, String>(
  (ref, tenantId) {
    final repository = ref.watch(customerRepositoryProvider);
    return repository.getCustomersStream(tenantId);
  },
);

final activeCustomersProvider = StreamProvider.family<List<Customer>, String>(
  (ref, tenantId) {
    final repository = ref.watch(customerRepositoryProvider);
    return repository.getActiveCustomersStream(tenantId);
  },
);

final topCustomersProvider = StreamProvider.family<List<Customer>, String>(
  (ref, tenantId) {
    final repository = ref.watch(customerRepositoryProvider);
    return repository.getTopCustomersStream(tenantId);
  },
);

final customerSearchProvider =
    FutureProvider.family<List<Customer>, (String, String)>(
  (ref, params) {
    final (tenantId, query) = params;
    final repository = ref.watch(customerRepositoryProvider);
    return repository.searchCustomers(tenantId, query);
  },
);
