import '../models/account.dart';
import '../models/product.dart';

Product mapGameAccountToProduct(GameAccount acc) {
  return Product(
    id: acc.id,
    sellerId: acc.sellerName,
    title: acc.title,
    description: acc.description,
    game: acc.gameName,
    price: acc.price,
    imageUrls: acc.imageUrls,
    tags: const [],
    stockStatus: acc.status == AccountStatus.available
        ? ProductStatus.available
        : ProductStatus.reserved,
    accountName: '',
    password: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

