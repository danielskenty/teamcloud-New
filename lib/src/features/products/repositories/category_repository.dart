import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../models/category.dart';

class CategoryRepository {
  CategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Category> _categoriesCollection(String tenantId) {
    return _firestore
        .collection(FirestorePaths.tenantCategories(tenantId))
        .withConverter(
          fromFirestore: (doc, _) => Category.fromFirestore(doc),
          toFirestore: (category, _) => category.toFirestore(),
        );
  }

  Future<void> createCategory(String tenantId, Category category) async {
    await _categoriesCollection(tenantId).doc(category.id).set(category);
  }

  Future<void> updateCategory(String tenantId, Category category) async {
    await _categoriesCollection(tenantId).doc(category.id).set(category);
  }

  Future<void> deleteCategory(String tenantId, String categoryId) async {
    await _categoriesCollection(tenantId).doc(categoryId).delete();
  }

  Future<Category?> getCategory(String tenantId, String categoryId) async {
    final doc = await _categoriesCollection(tenantId).doc(categoryId).get();
    return doc.data();
  }

  Stream<List<Category>> getCategoriesStream(String tenantId) {
    return _categoriesCollection(tenantId).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Stream<List<Category>> getActiveCategoriesStream(String tenantId) {
    return _categoriesCollection(tenantId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }
}
