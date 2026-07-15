import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/chat_screen.dart';
import '../widgets/marketplace/marketplace_image_carousel.dart';
import '../widgets/marketplace/marketplace_widgets.dart';
import '../widgets/marketplace/sticky_product_action_bar.dart';

class ProductDetailScreenRedesigned extends StatefulWidget {
  final Product product;
  const ProductDetailScreenRedesigned({super.key, required this.product});

  @override
  State<ProductDetailScreenRedesigned> createState() =>
      _ProductDetailScreenRedesignedState();
}

class _ProductDetailScreenRedesignedState
    extends State<ProductDetailScreenRedesigned> {
  late Product _product;
  bool _isRefreshing = false;
  String _sellerName = 'Seller';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loadSellerName();
  }

  @override
  void didUpdateWidget(
      covariant ProductDetailScreenRedesigned oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id) {
      _product = widget.product;
      _sellerName = 'Seller';
      _loadSellerName();
    }
  }

  Future<void> _loadSellerName() async {
    final sellerId = _product.sellerId;
    if (sellerId.trim().isEmpty) return;

    try {
      final sellerDoc =
          await _firestore.collection('users').doc(sellerId).get();
      if (!sellerDoc.exists) return;

      final name = sellerDoc.data()?['name'] as String?;
      final email = sellerDoc.data()?['email'] as String?;

      final resolved = (name != null && name.trim().isNotEmpty &&
              name != 'No name set')
          ? name
          : (email != null && email.trim().isNotEmpty ? email : null);

      if (resolved != null && mounted) {
        setState(() => _sellerName = resolved);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      final refreshed = await _productService.getProduct(_product.id);
      if (refreshed != null) {
        _product = refreshed;
        _sellerName = 'Seller';
        await _loadSellerName();
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.read<CartProvider>();

    final buyerId = auth.currentUser?.id ?? '';
    final sellerId = _product.sellerId;

    final tags = _product.tags.where((t) => t.trim().isNotEmpty).toList();

    final available = switch (_product.stockStatus) {
      ProductStatus.available => true,
      _ => false,
    };

    final desc = _product.description.trim();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _product.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                      child: Hero(
                        tag: 'product_${_product.id}_hero',
                        child: MarketplaceImageCarousel(
                          imageUrls: _product.imageUrls,
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
                            priceText: '${_product.price.toStringAsFixed(0)} đ',
                            gameText: _product.game,
                            sellerName: _sellerName,
                            available: available,
                          ),
                          const SizedBox(height: 14),
                          if (tags.isNotEmpty)
                            MarketplaceChipRow(chips: tags),
                          if (tags.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text('No tags'),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            'Description',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 10),
                          if (desc.isEmpty)
                            const Text('No description available.')
                          else
                            ExpandableText(
                              text: _product.description,
                              maxLines: 5,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(height: 1.5),
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: StickyProductActionBar(
              onContact: () async {
                if (buyerId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please login to contact the seller.'),
                    ),
                  );
                  return;
                }

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                final fallbackSellerName =
                    _sellerName.isNotEmpty ? _sellerName : 'Seller';

                if (context.mounted) {
                  Navigator.pop(context);

                  final rawName = auth.currentUser?.name ?? '';
                  final email = auth.currentUser?.email ?? 'Buyer';
                  final buyerName =
                      (rawName.trim().isNotEmpty && rawName != 'No name set')
                          ? rawName
                          : email;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        buyerId: buyerId,
                        buyerName: buyerName,
                        sellerId: sellerId,
                        sellerName: fallbackSellerName,
                        productId: _product.id,
                        productTitle: _product.title,
                      ),
                    ),
                  );
                }
              },
              onBuyNow: () async {
                if (!available) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This item is currently not available.'),
                    ),
                  );
                  return;
                }
                if (buyerId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please login to buy.'),
                    ),
                  );
                  return;
                }

                await cart.addToCart(_product);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to cart.')),
                );
              },
              onAddToCart: () async {
                if (!available) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This item is currently not available.'),
                    ),
                  );
                  return;
                }

                await cart.addToCart(_product);
                if (!context.mounted) return;
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
  final String sellerName;
  final bool available;

  const _InfoBlock({
    required this.priceText,
    required this.gameText,
    required this.sellerName,
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
          gameText,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w700),
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
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.35),
                ),
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
          'Seller: $sellerName',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}

