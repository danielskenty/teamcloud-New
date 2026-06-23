import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/models/product.dart';
import '../models/cart_item.dart';

class CartState {
  final List<CartItem> items;

  const CartState({this.items = const []});

  double get subtotal => items.fold(0, (s, it) => s + it.unitPrice * it.quantity);
  double get tax => subtotal * 0.12; // placeholder tax
  double get total => subtotal + tax;
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addProduct(Product product, {int qty = 1}) {
    final existingIndex = state.items.indexWhere((i) => i.productId == product.id);
    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final updated = existing.copyWith(quantity: existing.quantity + qty);
      final newItems = [...state.items];
      newItems[existingIndex] = updated;
      state = CartState(items: newItems);
    } else {
      final item = CartItem(
        productId: product.id,
        name: product.name,
        unitPrice: product.sellingPrice,
        quantity: qty,
      );
      state = CartState(items: [...state.items, item]);
    }
  }

  void removeProduct(String productId) {
    state = CartState(items: state.items.where((i) => i.productId != productId).toList());
  }

  void updateQuantity(String productId, int quantity) {
    final idx = state.items.indexWhere((i) => i.productId == productId);
    if (idx >= 0) {
      final updated = state.items[idx].copyWith(quantity: quantity);
      final newItems = [...state.items];
      newItems[idx] = updated;
      state = CartState(items: newItems);
    }
  }

  void clear() {
    state = const CartState(items: []);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
