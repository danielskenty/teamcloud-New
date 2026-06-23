import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory.dart';
import '../repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider((ref) {
  return InventoryRepository();
});

final inventoryStreamProvider = StreamProvider.family<List<Inventory>, String>(
  (ref, tenantId) {
    final repository = ref.watch(inventoryRepositoryProvider);
    return repository.getInventoryStream(tenantId);
  },
);

final branchInventoryProvider =
    StreamProvider.family<List<Inventory>, (String, String)>(
  (ref, params) {
    final (tenantId, branchId) = params;
    final repository = ref.watch(inventoryRepositoryProvider);
    return repository.getBranchInventoryStream(tenantId, branchId);
  },
);

final lowStockInventoryProvider = StreamProvider.family<List<Inventory>, String>(
  (ref, tenantId) {
    final repository = ref.watch(inventoryRepositoryProvider);
    return repository.getLowStockStream(tenantId);
  },
);
