/// Simple CartService singleton for managing cart items
class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  void addItem(Map<String, dynamic> item) {
    // Check if item already exists
    final existingIndex = _items.indexWhere((i) => i['id'] == item['id']);
    if (existingIndex != -1) {
      _items[existingIndex]['quantity'] = (_items[existingIndex]['quantity'] ?? 1) + 1;
    } else {
      _items.add({...item, 'quantity': 1});
    }
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item['id'] == itemId);
  }

  void decrementItem(String itemId) {
    final index = _items.indexWhere((i) => i['id'] == itemId);
    if (index != -1) {
      final currentQty = _items[index]['quantity'] ?? 1;
      if (currentQty > 1) {
        _items[index]['quantity'] = currentQty - 1;
      } else {
        _items.removeAt(index);
      }
    }
  }

  void incrementItem(String itemId) {
    final index = _items.indexWhere((i) => i['id'] == itemId);
    if (index != -1) {
      _items[index]['quantity'] = (_items[index]['quantity'] ?? 1) + 1;
    }
  }

  void clearCart() {
    _items.clear();
  }

  double getTotalPrice() {
    return _items.fold(0.0, (sum, item) {
      final price = (item['price'] ?? 0).toDouble();
      final quantity = item['quantity'] ?? 1;
      return sum + (price * quantity);
    });
  }

  int getTotalItemCount() {
    return _items.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 1));
  }

  String? getVendorId() {
    if (_items.isEmpty) return null;
    return _items.first['vendorId'];
  }
}
