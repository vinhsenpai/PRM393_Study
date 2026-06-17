import 'package:hive_flutter/hive_flutter.dart';

import '../models/cart_item.dart';

class CartService {
  static const String _boxName = 'local_cart_items_v2';


  Future<Box<CartItem>> openBox() async {
    // Storage is local-device only.
    return Hive.openBox<CartItem>(_boxName);
  }

  Future<Map<String, CartItem>> loadCart() async {
    final box = await openBox();
    final Map<String, CartItem> result = {};

    for (final key in box.keys) {
      final item = box.get(key);
      if (item != null && key != null) {
        result[key.toString()] = item;
      }
    }

    return result;
  }

  Future<void> putItem(String productId, CartItem item) async {
    final box = await openBox();
    await box.put(productId, item);
  }

  Future<void> removeItem(String productId) async {
    final box = await openBox();
    await box.delete(productId);
  }

  Future<void> clear() async {
    final box = await openBox();
    await box.clear();
  }
}

