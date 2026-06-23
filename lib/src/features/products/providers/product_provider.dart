import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

final productRepositoryProvider = Provider((ref) {
  return ProductRepository();
});

final productsStreamProvider = StreamProvider.family<List<Product>, String>(
  (ref, tenantId) {
    final repository = ref.watch(productRepositoryProvider);
    return repository.getProductsStream(tenantId);
  },
);

final productsByCategoryProvider = StreamProvider.family<List<Product>, (String, String)>(
  (ref, params) {
    final (tenantId, categoryId) = params;
    final repository = ref.watch(productRepositoryProvider);
    return repository.getProductsByCategoryStream(tenantId, categoryId);
  },
);

final lowStockProductsProvider = StreamProvider.family<List<Product>, String>(
  (ref, tenantId) {
    final repository = ref.watch(productRepositoryProvider);
    return repository.getLowStockProductsStream(tenantId);
  },
);

final productSearchProvider =
    FutureProvider.family<List<Product>, (String, String)>(
  (ref, params) {
    final (tenantId, query) = params;
    final repository = ref.watch(productRepositoryProvider);
    return repository.searchProducts(tenantId, query);
  },
);
