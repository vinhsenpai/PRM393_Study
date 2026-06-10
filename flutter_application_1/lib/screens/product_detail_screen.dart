import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/chat_screen.dart';
import '../theme/app_theme.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.read<CartProvider>();

    final buyerId = auth.currentUser?.id ?? '';
    final sellerId = product.sellerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 220,
              child: product.imageUrls.isNotEmpty
                  ? Image.network(
                      product.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported, size: 48),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported, size: 48),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${product.price.toStringAsFixed(0)} đ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Game: ${product.game}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            product.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StockChip(status: product.stockStatus),
              if (product.tags.isNotEmpty)
                for (final tag in product.tags.take(6))
                  Chip(
                    label: Text(tag),
                    side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
                  ),
            ],
          ),

          const SizedBox(height: 24),

          if (buyerId.isEmpty) ...[
            const Text('Bạn cần đăng nhập để mua hàng và chat với seller.'),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  cart.addProduct(product);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã thêm vào giỏ hàng')),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to cart'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.7)),
                ),
                onPressed: () {
                  if (sellerId.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        buyerId: buyerId,
                        sellerId: sellerId,
                        productId: product.id,
                        productTitle: product.title,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Chat với seller'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  final ProductStatus status;

  const _StockChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ProductStatus.available:
        color = Colors.green;
        break;
      case ProductStatus.reserved:
        color = Colors.orange;
        break;
      case ProductStatus.sold:
        color = Colors.red;
        break;
      case ProductStatus.hidden:
        color = Colors.grey;
        break;
    }

    return Chip(
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      label: Text(
        status.toString().split('.').last.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

