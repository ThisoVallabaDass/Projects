import 'product_model.dart';

/// Cart item model that wraps a product with quantity tracking
class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  /// Calculate total price for this cart item
  double get totalPrice => product.price * quantity;

  /// Increment quantity by 1
  void increment() {
    quantity++;
  }

  /// Decrement quantity by 1 (minimum 0)
  void decrement() {
    if (quantity > 0) {
      quantity--;
    }
  }
}
