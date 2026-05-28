import '../models/account.dart';

class CartItem {
  final String id;
  final GameAccount account;
  int quantity;

  CartItem({
    required this.id,
    required this.account,
    this.quantity = 1,
  });

  double get totalPrice => account.price * quantity;
}
