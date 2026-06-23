class CartItem {
  final String productId;
  final String name;
  final double unitPrice;
  final int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });

  CartItem copyWith({
    String? productId,
    String? name,
    double? unitPrice,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': name,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'total': unitPrice * quantity,
      };
}
