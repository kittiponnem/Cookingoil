import 'package:flutter/foundation.dart';

class CartItem {
  final String productId;
  final String title;
  int quantity;
  final double price;

  CartItem({
    required this.productId,
    required this.title,
    required this.quantity,
    required this.price,
  });

  double get lineTotal => quantity * price;
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};
  
  int get itemCount => _items.length;
  
  int get totalQuantity => _items.values.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalAmount => _items.values.fold(0.0, (sum, item) => sum + item.lineTotal);

  bool get isEmpty => _items.isEmpty;

  void addItem(String productId, String title, double price) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity++;
    } else {
      _items[productId] = CartItem(
        productId: productId,
        title: title,
        quantity: 1,
        price: price,
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;
    
    if (_items[productId]!.quantity > 1) {
      _items[productId]!.quantity--;
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity <= 0) {
        _items.remove(productId);
      } else {
        _items[productId]!.quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  CartItem? getItem(String productId) {
    return _items[productId];
  }
}
