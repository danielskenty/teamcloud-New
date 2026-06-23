import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String tenantId;
  final String name;
  final String description;
  final String sku;
  final String barcode;
  final double costPrice;
  final double sellingPrice;
  final String categoryId;
  final String? brandId;
  final int quantity;
  final int reorderLevel;
  final String unit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl;

  Product({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.description,
    required this.sku,
    required this.barcode,
    required this.costPrice,
    required this.sellingPrice,
    required this.categoryId,
    this.brandId,
    required this.quantity,
    required this.reorderLevel,
    required this.unit,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
  });

  Product copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? description,
    String? sku,
    String? barcode,
    double? costPrice,
    double? sellingPrice,
    String? categoryId,
    String? brandId,
    int? quantity,
    int? reorderLevel,
    String? unit,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      quantity: quantity ?? this.quantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Product.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return Product(
      id: doc.id,
      tenantId: data['tenantId'],
      name: data['name'],
      description: data['description'],
      sku: data['sku'],
      barcode: data['barcode'],
      costPrice: (data['costPrice'] as num).toDouble(),
      sellingPrice: (data['sellingPrice'] as num).toDouble(),
      categoryId: data['categoryId'],
      brandId: data['brandId'],
      quantity: data['quantity'],
      reorderLevel: data['reorderLevel'],
      unit: data['unit'],
      isActive: data['isActive'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tenantId': tenantId,
      'name': name,
      'description': description,
      'sku': sku,
      'barcode': barcode,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'categoryId': categoryId,
      'brandId': brandId,
      'quantity': quantity,
      'reorderLevel': reorderLevel,
      'unit': unit,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'imageUrl': imageUrl,
    };
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, sku: $sku, quantity: $quantity)';
  }
}
