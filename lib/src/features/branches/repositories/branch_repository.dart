import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';

class BranchRepository {
  BranchRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> branchesRef(String tenantId) {
    return _firestore.collection(FirestorePaths.tenantBranches(tenantId));
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getBranches(String tenantId) {
    return branchesRef(tenantId).get();
  }

  Future<void> createBranch(String tenantId, Map<String, dynamic> data) {
    return branchesRef(tenantId).add(data);
  }

  Future<void> updateBranch(String tenantId, String branchId, Map<String, dynamic> data) {
    return branchesRef(tenantId).doc(branchId).update(data);
  }
}
