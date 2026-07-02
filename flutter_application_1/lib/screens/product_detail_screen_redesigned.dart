import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/chat_screen.dart';
import '../widgets/marketplace/marketplace_image_carousel.dart';
import '../widgets/marketplace/marketplace_widgets.dart';
import '../widgets/marketplace/sticky_product_action_bar.dart';

class ProductDetailScreenRedesigned extends StatelessWidget {
  final Product product;
  const ProductDetailScreenRedesigned({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.read<CartProvider>();

    final buyerId = auth.currentUser?.id ?? '';
    final sellerId = product.sellerId;

    final tags = product.tags.where((t) => t.trim().isNotEmpty).toList();

    final available = switch (product.stockStatus) {
      ProductStatus.available => true,
      _ => false,
    };

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async {
                // Stateless fallback: no-op refresh.
                // Stream/Fetch can be added later if you convert this to a StatefulWidget.
                await Future<void>.delayed(const Duration(milliseconds: 300));
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                      child: Hero(
                        tag: 'product_${product.id}_hero',
                        child: MarketplaceImageCarousel(
                          imageUrls: product.imageUrls,
                          height: 320,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoBlock(
                            priceText: '${product.price.toStringAsFixed(0)} đ',
                            gameText: product.game,
                            sellerId: sellerId,
                            available: available,
                          ),
                          const SizedBox(height: 14),
                          if (tags.isNotEmpty) MarketplaceChipRow(chips: tags),
                          if (tags.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text('No tags'),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          if (product.description.trim().isEmpty)
                            const Text('No description available.'),
                          if (product.description.trim().isNotEmpty)
                            ExpandableText(
                              text: product.description,
                              maxLines: 5,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                              readMoreText: 'Read more',
                              readLessText: 'Read less',
                            ),
                          const SizedBox(height: 88),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sticky bottom action bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: StickyProductActionBar(
              onContact: () async {
                if (buyerId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please login to contact the seller.')),
                  );
                  return;
                }
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                String sellerName = 'Seller';
                try {
                  final sellerDoc = await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
                  if (sellerDoc.exists) {
                    final name = sellerDoc.data()?['name'] as String?;
                    final email = sellerDoc.data()?['email'] as String?;
                    if (name != null && name.trim().isNotEmpty && name != 'No name set') {
                      sellerName = name;
                    } else if (email != null && email.trim().isNotEmpty) {
                      sellerName = email;
                    }
                  }
                } catch (e) {
                  // Ignored
                }

                if (context.mounted) {
                  Navigator.pop(context); // Dismiss loading dialog

                  final rawName = auth.currentUser?.name ?? '';
                  final email = auth.currentUser?.email ?? 'Buyer';
                  final buyerName = (rawName.trim().isNotEmpty && rawName != 'No name set') ? rawName : email;
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        buyerId: buyerId,
                        buyerName: buyerName,
                        sellerId: sellerId,
                        sellerName: sellerName,
                        productId: product.id,
                        productTitle: product.title,
                      ),
                    ),
                  );
                }
              },
              onBuyNow: () async {
                // Checkout logic is intentionally not implemented.
                if (!available) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This item is currently not available.')),
                  );
                  return;
                }
                if (buyerId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please login to buy.')),
                  );
                  return;
                }

                await cart.addToCart(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to cart.')),
                );
              },
              onAddToCart: () async {
                if (!available) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This item is currently not available.')),
                  );
                  return;
                }
                await cart.addToCart(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to cart.')),
                );
              },

            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String priceText;
  final String gameText;
  final String sellerId;
  final bool available;

  const _InfoBlock({
    required this.priceText,
    required this.gameText,
    required this.sellerId,
    required this.available,
  });

  Color _badgeColor(BuildContext context) {
    if (available) return Colors.green;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          // Title comes from appBar hero tag; keep a subtle header here.
          // If you want duplicate, remove this.
          gameText,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                priceText,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                available ? 'Available' : 'Sold Out',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Seller: $sellerId',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}

