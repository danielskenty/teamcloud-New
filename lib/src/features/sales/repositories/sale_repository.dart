import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../models/sale.dart';

class SaleRepository {
  SaleRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Sale> _salesCollection(String tenantId) {
    return _firestore.collection(FirestorePaths.tenantSales(tenantId)).withConverter(
          fromFirestore: (doc, _) => Sale.fromFirestore(doc),
          toFirestore: (sale, _) => sale.toFirestore(),
        );
  }

  Future<void> createSale(String tenantId, Sale sale) async {
    await _salesCollection(tenantId).doc(sale.id).set(sale);
  }

  Future<void> updateSale(String tenantId, Sale sale) async {
    await _salesCollection(tenantId).doc(sale.id).set(sale);
  }

  Future<Sale?> getSale(String tenantId, String saleId) async {
    final doc = await _salesCollection(tenantId).doc(saleId).get();
    return doc.data();
  }

  Stream<List<Sale>> getSalesStream(String tenantId) {
    return _salesCollection(tenantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Stream<List<Sale>> getBranchSalesStream(String tenantId, String branchId) {
    return _salesCollection(tenantId)
        .where('branchId', isEqualTo: branchId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Stream<List<Sale>> getCustomerSalesStream(
    String tenantId,
    String customerId,
  ) {
    return _salesCollection(tenantId)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Future<List<Sale>> getSalesByDateRange(
    String tenantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final docs = await _salesCollection(tenantId)
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate)
        .orderBy('createdAt', descending: true)
        .get();
    return docs.docs.map((doc) => doc.data()).toList();
  }
}
