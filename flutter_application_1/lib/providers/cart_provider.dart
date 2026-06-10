import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/account.dart';
import '../models/product.dart';

class ProductCartItem {
  final String id;
  final Product product;
  int quantity;

  ProductCartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;
}


class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  // Product-based cart (for buyer interactions)
  final Map<String, ProductCartItem> _productItems = {};


  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _productItems.forEach((key, cartItem) {
      total += cartItem.totalPrice;
    });
    return total;
  }


  void addItem(GameAccount account) {
    // Legacy cart item for GameAccount (kept for backward compatibility)

    if (_items.containsKey(account.id)) {
      _items.update(
        account.id,
        (existingItem) => CartItem(
          id: existingItem.id,
          account: existingItem.account,
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        account.id,
        () => CartItem(
          id: DateTime.now().toString(),
          account: account,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String accountId) {
    _items.remove(accountId);
    notifyListeners();
  }

  void addProduct(Product product) {
    final key = product.id;
    if (_productItems.containsKey(key)) {
      _productItems[key]!.quantity += 1;
    } else {
      _productItems[key] = ProductCartItem(
        id: DateTime.now().toString(),
        product: product,
      );
    }
    notifyListeners();
  }

  void removeProduct(String productId) {
    _productItems.remove(productId);
    notifyListeners();
  }

  Map<String, ProductCartItem> get productItems => {..._productItems};

  void clear() {
    _items.clear();
    _productItems.clear();
    notifyListeners();
  }

}
