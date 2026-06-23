import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';

final categoryRepositoryProvider = Provider((ref) {
  return CategoryRepository();
});

final categoriesStreamProvider = StreamProvider.family<List<Category>, String>(
  (ref, tenantId) {
    final repository = ref.watch(categoryRepositoryProvider);
    return repository.getCategoriesStream(tenantId);
  },
);

final activeCategoriesProvider = StreamProvider.family<List<Category>, String>(
  (ref, tenantId) {
    final repository = ref.watch(categoryRepositoryProvider);
    return repository.getActiveCategoriesStream(tenantId);
  },
);
