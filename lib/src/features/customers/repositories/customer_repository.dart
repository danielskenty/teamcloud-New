import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../models/customer.dart';

class CustomerRepository {
  CustomerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Customer> _customersCollection(String tenantId) {
    return _firestore
        .collection(FirestorePaths.tenantCustomers(tenantId))
        .withConverter(
          fromFirestore: (doc, _) => Customer.fromFirestore(doc),
          toFirestore: (customer, _) => customer.toFirestore(),
        );
  }

  Future<void> createCustomer(String tenantId, Customer customer) async {
    await _customersCollection(tenantId).doc(customer.id).set(customer);
  }

  Future<void> updateCustomer(String tenantId, Customer customer) async {
    await _customersCollection(tenantId).doc(customer.id).set(customer);
  }

  Future<void> deleteCustomer(String tenantId, String customerId) async {
    await _customersCollection(tenantId).doc(customerId).delete();
  }

  Future<Customer?> getCustomer(String tenantId, String customerId) async {
    final doc = await _customersCollection(tenantId).doc(customerId).get();
    return doc.data();
  }

  Stream<List<Customer>> getCustomersStream(String tenantId) {
    return _customersCollection(tenantId).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Stream<List<Customer>> getActiveCustomersStream(String tenantId) {
    return _customersCollection(tenantId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Stream<List<Customer>> getTopCustomersStream(String tenantId) {
    return _customersCollection(tenantId)
        .orderBy('totalSpent', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Future<List<Customer>> searchCustomers(
    String tenantId,
    String query,
  ) async {
    final docs = await _customersCollection(tenantId).get();
    final customers = docs.docs.map((doc) => doc.data()).toList();
    return customers
        .where((customer) =>
            customer.name.toLowerCase().contains(query.toLowerCase()) ||
            customer.email.toLowerCase().contains(query.toLowerCase()) ||
            customer.phone.contains(query))
        .toList();
  }

  Future<void> updateLoyaltyPoints(
    String tenantId,
    String customerId,
    double points,
  ) async {
    final customer = await getCustomer(tenantId, customerId);
    if (customer != null) {
      final updated = customer.copyWith(
        loyaltyPoints: customer.loyaltyPoints + points,
        updatedAt: DateTime.now(),
      );
      await updateCustomer(tenantId, updated);
    }
  }
}
