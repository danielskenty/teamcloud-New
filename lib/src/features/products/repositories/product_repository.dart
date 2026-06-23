import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../models/product.dart';

class ProductRepository {
  ProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Product> _productsCollection(String tenantId) {
    return _firestore
        .collection(FirestorePaths.tenantProducts(tenantId))
        .withConverter(
          fromFirestore: (doc, _) => Product.fromFirestore(doc),
          toFirestore: (product, _) => product.toFirestore(),
        );
  }

  Future<void> createProduct(String tenantId, Product product) async {
    await _productsCollection(tenantId).doc(product.id).set(product);
  }

  Future<void> updateProduct(String tenantId, Product product) async {
    await _productsCollection(tenantId).doc(product.id).set(product);
  }

  Future<void> deleteProduct(String tenantId, String productId) async {
    await _productsCollection(tenantId).doc(productId).delete();
  }

  Future<Product?> getProduct(String tenantId, String productId) async {
    final doc = await _productsCollection(tenantId).doc(productId).get();
    return doc.data();
  }

  Stream<List<Product>> getProductsStream(String tenantId) {
    return _productsCollection(tenantId).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Stream<List<Product>> getProductsByCategoryStream(
    String tenantId,
    String categoryId,
  ) {
    return _productsCollection(tenantId)
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Stream<List<Product>> getLowStockProductsStream(String tenantId) {
    return _productsCollection(tenantId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data())
              .where((product) => product.quantity <= product.reorderLevel)
              .toList(),
        );
  }

  Future<List<Product>> searchProducts(
    String tenantId,
    String query,
  ) async {
    final docs = await _productsCollection(tenantId).get();
    final products = docs.docs.map((doc) => doc.data()).toList();
    return products
        .where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.sku.toLowerCase().contains(query.toLowerCase()) ||
            product.barcode.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
