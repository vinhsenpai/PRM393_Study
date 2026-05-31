import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/account.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {
    '1': CartItem(
      id: 'dummy_1',
      account: GameAccount.dummyAccounts[0],
      quantity: 1,
    ),
    '2': CartItem(
      id: 'dummy_2',
      account: GameAccount.dummyAccounts[1],
      quantity: 1,
    ),
  };

  CartProvider();

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.totalPrice;
    });
    return total;
  }

  void addItem(GameAccount account) {
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
        () => CartItem(id: DateTime.now().toString(), account: account),
      );
    }
    notifyListeners();
  }

  void removeItem(String accountId) {
    _items.remove(accountId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
