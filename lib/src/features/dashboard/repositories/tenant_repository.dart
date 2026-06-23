import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';

class TenantRepository {
  TenantRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> tenantRef(String tenantId) {
    return _firestore.doc(FirestorePaths.tenantDoc(tenantId));
  }

  CollectionReference<Map<String, dynamic>> branchesRef(String tenantId) {
    return _firestore.collection(FirestorePaths.tenantBranches(tenantId));
  }

  CollectionReference<Map<String, dynamic>> productsRef(String tenantId) {
    return _firestore.collection(FirestorePaths.tenantProducts(tenantId));
  }

  CollectionReference<Map<String, dynamic>> salesRef(String tenantId) {
    return _firestore.collection(FirestorePaths.tenantSales(tenantId));
  }

  Future<void> createTenant(String tenantId, Map<String, dynamic> data) {
    return tenantRef(tenantId).set(data);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getTenant(String tenantId) {
    return tenantRef(tenantId).get();
  }
}
