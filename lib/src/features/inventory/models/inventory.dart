import 'package:cloud_firestore/cloud_firestore.dart';

class Inventory {
  final String id;
  final String tenantId;
  final String productId;
  final String branchId;
  final int quantity;
  final int reserved;
  final int available;
  final DateTime lastRestocked;
  final DateTime updatedAt;

  Inventory({
    required this.id,
    required this.tenantId,
    required this.productId,
    required this.branchId,
    required this.quantity,
    required this.reserved,
    required this.available,
    required this.lastRestocked,
    required this.updatedAt,
  });

  Inventory copyWith({
    String? id,
    String? tenantId,
    String? productId,
    String? branchId,
    int? quantity,
    int? reserved,
    int? available,
    DateTime? lastRestocked,
    DateTime? updatedAt,
  }) {
    return Inventory(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      productId: productId ?? this.productId,
      branchId: branchId ?? this.branchId,
      quantity: quantity ?? this.quantity,
      reserved: reserved ?? this.reserved,
      available: available ?? this.available,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Inventory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return Inventory(
      id: doc.id,
      tenantId: data['tenantId'],
      productId: data['productId'],
      branchId: data['branchId'],
      quantity: data['quantity'],
      reserved: data['reserved'],
      available: data['available'],
      lastRestocked: (data['lastRestocked'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tenantId': tenantId,
      'productId': productId,
      'branchId': branchId,
      'quantity': quantity,
      'reserved': reserved,
      'available': available,
      'lastRestocked': Timestamp.fromDate(lastRestocked),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  String toString() {
    return 'Inventory(id: $id, productId: $productId, quantity: $quantity)';
  }
}
