import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String tenantId;
  final String name;
  final String email;
  final String phone;
  final String? address;
  final String? city;
  final String? country;
  final String? postalCode;
  final double loyaltyPoints;
  final double totalSpent;
  final DateTime lastPurchase;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.email,
    required this.phone,
    this.address,
    this.city,
    this.country,
    this.postalCode,
    required this.loyaltyPoints,
    required this.totalSpent,
    required this.lastPurchase,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Customer copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? country,
    String? postalCode,
    double? loyaltyPoints,
    double? totalSpent,
    DateTime? lastPurchase,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalSpent: totalSpent ?? this.totalSpent,
      lastPurchase: lastPurchase ?? this.lastPurchase,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Customer.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return Customer(
      id: doc.id,
      tenantId: data['tenantId'],
      name: data['name'],
      email: data['email'],
      phone: data['phone'],
      address: data['address'],
      city: data['city'],
      country: data['country'],
      postalCode: data['postalCode'],
      loyaltyPoints: (data['loyaltyPoints'] as num).toDouble(),
      totalSpent: (data['totalSpent'] as num).toDouble(),
      lastPurchase: (data['lastPurchase'] as Timestamp).toDate(),
      isActive: data['isActive'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tenantId': tenantId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'country': country,
      'postalCode': postalCode,
      'loyaltyPoints': loyaltyPoints,
      'totalSpent': totalSpent,
      'lastPurchase': Timestamp.fromDate(lastPurchase),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, phone: $phone)';
  }
}
