import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/chat_screen.dart';
import '../screens/checkout_screen.dart';
import '../navigation/buyer_navigation_shell.dart';
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
      backgroundColor: const Color(0xFF0F172A), // Background Dark
      appBar: AppBar(
        title: Text(
          _product.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: const Color(0xFF6366F1),
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
                          child: Text(
                            'No tags',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Description',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF8FAFC),
                            ),
                      ),
                      const SizedBox(height: 10),
                      if (desc.isEmpty)
                        const Text(
                          'No description available.',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        )
                      else
                        ExpandableText(
                          text: _product.description,
                          maxLines: 5,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.5, color: const Color(0xFF94A3B8)),
                          readMoreText: 'Read more',
                          readLessText: 'Read less',
                        ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: StickyProductActionBar(
        isAvailable: available,
        onContact: () async {
          if (buyerId.isEmpty) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please login to contact the seller.'),
                duration: Duration(seconds: 2),
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
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This item is currently not available.'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          if (buyerId.isEmpty) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please login to buy.'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }

          await cart.addToCart(_product);
          if (!context.mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
          );
        },
        onAddToCart: () async {
          if (!available) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This item is currently not available.'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }

          await cart.addToCart(_product);
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1E293B),
              duration: const Duration(seconds: 2),
              content: const Text(
                'Product added to cart!',
                style: TextStyle(color: Color(0xFFF8FAFC)),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFF334155)),
              ),
              action: SnackBarAction(
                label: 'VIEW CART',
                textColor: const Color(0xFF6366F1),
                onPressed: () {
                  final shellContext = BuyerNavigationShell.navKey.currentContext;
                  if (shellContext != null) {
                    ScaffoldMessenger.of(shellContext).hideCurrentSnackBar();
                    Navigator.of(shellContext).popUntil((route) => route.isFirst);
                    BuyerNavigationShell.navKey.currentState?.setSelectedIndex(1);
                  }
                },
              ),
            ),
          );
        },
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
    if (available) return const Color(0xFF10B981);
    return const Color(0xFFEF4444);
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
              ?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF6366F1)),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                priceText,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF59E0B), // Accent Amber Price
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.3),
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
              ?.copyWith(color: const Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}
