import 'package:cloud_firestore/cloud_firestore.dart';

class SaleItem {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double discount;
  final double total;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.discount,
    required this.total,
  });

  factory SaleItem.fromFirestore(Map<String, dynamic> data) {
    return SaleItem(
      productId: data['productId'],
      productName: data['productName'],
      unitPrice: (data['unitPrice'] as num).toDouble(),
      quantity: data['quantity'],
      discount: (data['discount'] as num).toDouble(),
      total: (data['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'discount': discount,
      'total': total,
    };
  }
}

class Sale {
  final String id;
  final String tenantId;
  final String branchId;
  final String cashierId;
  final String? customerId;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final String status;
  final String? paymentRef;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sale({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.cashierId,
    this.customerId,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.status,
    this.paymentRef,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Sale copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? cashierId,
    String? customerId,
    List<SaleItem>? items,
    double? subtotal,
    double? discount,
    double? tax,
    double? total,
    String? paymentMethod,
    String? status,
    String? paymentRef,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sale(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      cashierId: cashierId ?? this.cashierId,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      paymentRef: paymentRef ?? this.paymentRef,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Sale.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return Sale(
      id: doc.id,
      tenantId: data['tenantId'],
      branchId: data['branchId'],
      cashierId: data['cashierId'],
      customerId: data['customerId'],
      items: (data['items'] as List)
          .map((item) => SaleItem.fromFirestore(item))
          .toList(),
      subtotal: (data['subtotal'] as num).toDouble(),
      discount: (data['discount'] as num).toDouble(),
      tax: (data['tax'] as num).toDouble(),
      total: (data['total'] as num).toDouble(),
      paymentMethod: data['paymentMethod'],
      status: data['status'],
      paymentRef: data['paymentRef'],
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tenantId': tenantId,
      'branchId': branchId,
      'cashierId': cashierId,
      'customerId': customerId,
      'items': items.map((item) => item.toFirestore()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'paymentMethod': paymentMethod,
      'status': status,
      'paymentRef': paymentRef,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  String toString() {
    return 'Sale(id: $id, total: $total, status: $status, paymentRef: $paymentRef)';
  }
}
