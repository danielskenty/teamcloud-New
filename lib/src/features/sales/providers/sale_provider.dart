import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale.dart';
import '../repositories/sale_repository.dart';

final saleRepositoryProvider = Provider((ref) {
  return SaleRepository();
});

final salesStreamProvider = StreamProvider.family<List<Sale>, String>(
  (ref, tenantId) {
    final repository = ref.watch(saleRepositoryProvider);
    return repository.getSalesStream(tenantId);
  },
);

final branchSalesProvider = StreamProvider.family<List<Sale>, (String, String)>(
  (ref, params) {
    final (tenantId, branchId) = params;
    final repository = ref.watch(saleRepositoryProvider);
    return repository.getBranchSalesStream(tenantId, branchId);
  },
);

final customerSalesProvider = StreamProvider.family<List<Sale>, (String, String)>(
  (ref, params) {
    final (tenantId, customerId) = params;
    final repository = ref.watch(saleRepositoryProvider);
    return repository.getCustomerSalesStream(tenantId, customerId);
  },
);
