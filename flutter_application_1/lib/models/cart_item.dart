class CartItem {
  final String productId;
  final String title;
  final double price;
  final String imageUrl;
  final int quantity;
  final String sellerId;
  final String game;
  final String stockStatus;
  final DateTime addedAt;

  const CartItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.sellerId,
    required this.game,
    required this.stockStatus,
    required this.addedAt,
  });

  CartItem copyWith({
    String? productId,
    String? title,
    double? price,
    String? imageUrl,
    int? quantity,
    String? sellerId,
    String? game,
    String? stockStatus,
    DateTime? addedAt,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      title: title ?? this.title,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      sellerId: sellerId ?? this.sellerId,
      game: game ?? this.game,
      stockStatus: stockStatus ?? this.stockStatus,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}



