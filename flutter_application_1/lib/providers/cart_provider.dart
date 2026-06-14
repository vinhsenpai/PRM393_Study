import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService;

  CartProvider({CartService? cartService}) : _cartService = cartService ?? CartService();

  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  int get totalItems => _items.values.fold<int>(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.values.fold<double>(0.0, (sum, item) => sum + item.price * item.quantity);

  bool containsProduct(String productId) => _items.containsKey(productId);

  Future<void> loadCart() async {
    final loaded = await _cartService.loadCart();
    _items
      ..clear()
      ..addAll(loaded);
    notifyListeners();
  }

  Future<void> addToCart(Product product, {String? imageUrlOverride}) async {
    final productId = product.id;

    final imageUrl = (imageUrlOverride ?? (product.imageUrls.isNotEmpty ? product.imageUrls.first : '')).trim();

    if (_items.containsKey(productId)) {
      final existing = _items[productId]!;
      final updated = existing.copyWith(quantity: existing.quantity + 1);
      _items[productId] = updated;
      await _cartService.putItem(productId, updated);
      notifyListeners();
      return;
    }

    final item = CartItem(
      productId: productId,
      title: product.title,
      price: product.price,
      imageUrl: imageUrl,
      quantity: 1,
      sellerId: product.sellerId,
      game: product.game,
      stockStatus: product.stockStatus.toString().split('.').last,
      addedAt: DateTime.now(),
    );

    _items[productId] = item;
    await _cartService.putItem(productId, item);
    notifyListeners();
  }

  Future<void> removeFromCart(String productId) async {
    _items.remove(productId);
    await _cartService.removeItem(productId);
    notifyListeners();
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    if (!_items.containsKey(productId)) return;

    final clamped = newQuantity < 1 ? 1 : newQuantity;
    final existing = _items[productId]!;
    final updated = existing.copyWith(quantity: clamped);

    _items[productId] = updated;
    await _cartService.putItem(productId, updated);
    notifyListeners();
  }

  Future<void> changeQuantityBy(String productId, int delta) async {
    if (!_items.containsKey(productId)) return;

    final existing = _items[productId]!;
    await updateQuantity(productId, existing.quantity + delta);
  }

  bool get isEmpty => _items.isEmpty;

  Future<void> clearCart() async {
    _items.clear();
    await _cartService.clear();
    notifyListeners();
  }
}

