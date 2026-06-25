import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final String game;
  final double price;
  final List<String> imageUrls;
  final List<String> tags;
  final ProductStatus stockStatus;
  final String accountName;
  final String password;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.game,
    required this.price,
    required this.imageUrls,
    required this.tags,
    required this.stockStatus,
    required this.accountName,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      sellerId: data['sellerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      game: data['game'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      stockStatus: _parseProductStatus(data['stockStatus']),
      accountName: data['accountName'] as String? ?? '',
      password: data['password'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static ProductStatus _parseProductStatus(dynamic status) {
    if (status is String) {
      switch (status) {
        case 'available':
          return ProductStatus.available;
        case 'reserved':
          return ProductStatus.reserved;
        case 'sold':
          return ProductStatus.sold;
        case 'hidden':
          return ProductStatus.hidden;
        default:
          return ProductStatus.available;
      }
    }
    return ProductStatus.available;
  }

  Map<String, dynamic> toDocument() {
    return {
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'game': game,
      'price': price,
      'imageUrls': imageUrls,
      'tags': tags,
      'stockStatus': stockStatus.toString().split('.').last,
      'accountName': accountName,
      'password': password,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

enum ProductStatus { available, reserved, sold, hidden }