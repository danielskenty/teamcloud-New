import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../models/inventory.dart';

class InventoryRepository {
  InventoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Inventory> _inventoryCollection(String tenantId) {
    return _firestore
        .collection(FirestorePaths.tenantInventory(tenantId))
        .withConverter(
          fromFirestore: (doc, _) => Inventory.fromFirestore(doc),
          toFirestore: (inventory, _) => inventory.toFirestore(),
        );
  }

  Future<void> createInventory(String tenantId, Inventory inventory) async {
    await _inventoryCollection(tenantId).doc(inventory.id).set(inventory);
  }

  Future<void> updateInventory(String tenantId, Inventory inventory) async {
    await _inventoryCollection(tenantId).doc(inventory.id).set(inventory);
  }

  Future<void> deleteInventory(String tenantId, String inventoryId) async {
    await _inventoryCollection(tenantId).doc(inventoryId).delete();
  }

  Future<Inventory?> getInventory(String tenantId, String inventoryId) async {
    final doc = await _inventoryCollection(tenantId).doc(inventoryId).get();
    return doc.data();
  }

  Stream<List<Inventory>> getInventoryStream(String tenantId) {
    return _inventoryCollection(tenantId).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Stream<List<Inventory>> getBranchInventoryStream(
    String tenantId,
    String branchId,
  ) {
    return _inventoryCollection(tenantId)
        .where('branchId', isEqualTo: branchId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Stream<List<Inventory>> getLowStockStream(String tenantId) {
    return _inventoryCollection(tenantId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data())
              .where((inv) => inv.available <= 10)
              .toList(),
        );
  }

  Future<void> adjustStock(
    String tenantId,
    String inventoryId,
    int quantity,
  ) async {
    final inventory = await getInventory(tenantId, inventoryId);
    if (inventory != null) {
      final updated = inventory.copyWith(
        quantity: inventory.quantity + quantity,
        available: inventory.available + quantity,
        updatedAt: DateTime.now(),
      );
      await updateInventory(tenantId, updated);
    }
  }
}
