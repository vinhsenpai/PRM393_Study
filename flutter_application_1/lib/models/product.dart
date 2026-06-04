import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductStatus { available, reserved, sold, hidden }

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
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromDocument(Map<String, dynamic> doc) {
    return Product(
      id: doc['id'] as String,
      sellerId: doc['sellerId'] as String,
      title: doc['title'] as String,
      description: doc['description'] as String,
      game: doc['game'] as String,
      price: (doc['price'] as num).toDouble(),
      imageUrls: List<String>.from(doc['imageUrls'] ?? []),
      tags: List<String>.from(doc['tags'] ?? []),
      stockStatus: _parseProductStatus(doc['stockStatus']),
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
      updatedAt: (doc['updatedAt'] as Timestamp).toDate(),
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
      'id': id,
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'game': game,
      'price': price,
      'imageUrls': imageUrls,
      'tags': tags,
      'stockStatus': stockStatus.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}