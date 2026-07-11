import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../widgets/marketplace/marketplace_product_card.dart';

class FavoritesScreen extends StatelessWidget {
  final String userId;

  const FavoritesScreen({super.key, required this.userId});

  Stream<List<Product>> _getFavoriteProducts() {
    return FirebaseFirestore.instance
        .collection('favorites')
        .doc(userId)
        .collection('items')
        .snapshots()
        .asyncMap((snapshot) async {
      final productIds = snapshot.docs.map((doc) => doc.id).toList();
      if (productIds.isEmpty) {
        return [];
      }
      final productSnapshots = await FirebaseFirestore.instance
          .collection('products')
          .where(FieldPath.documentId, whereIn: productIds)
          .get();
      return productSnapshots.docs
          .map((doc) => Product.fromDocument(doc))
          .toList();
    });
  }

  Future<void> _toggleFavorite(String productId) async {
    final favoriteRef = FirebaseFirestore.instance
        .collection('favorites')
        .doc(userId)
        .collection('items')
        .doc(productId);

    final doc = await favoriteRef.get();
    if (doc.exists) {
      await favoriteRef.delete();
    } else {
      await favoriteRef.set({});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: StreamBuilder<List<Product>>(
        stream: _getFavoriteProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final favoriteProducts = snapshot.data ?? [];

          if (favoriteProducts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'You have no favorites yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on products to add them to your favorites',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: favoriteProducts.length,
            itemBuilder: (context, index) {
              final product = favoriteProducts[index];
              return MarketplaceProductCard(
                product: product,
                onTap: () {
                  // TODO: Navigate to product detail
                },
                onFavorite: () {
                  _toggleFavorite(product.id);
                },
                isFavorite: true, // Since we are in favorites screen, assume it's favorite
              );
            },
          );
        },
      ),
    );
  }
}