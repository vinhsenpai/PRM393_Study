import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../services/product_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/marketplace/marketplace_product_card.dart';
import '../widgets/marketplace/marketplace_widgets.dart';

// Backward compatible alias: the catalog screen previously referenced a widget
// named `ProductDetailScreen`. This project uses `ProductDetailScreenRedesigned`.
import 'product_detail_screen_redesigned.dart' as detail;

class ProductCatalogScreen extends StatelessWidget {
  final bool hideAppBar;
  final String searchQuery;
  final String? category;

  const ProductCatalogScreen({
    super.key,
    this.hideAppBar = false,
    this.searchQuery = '',
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    if (hideAppBar) {
      return _ProductCatalogBody(
        searchQuery: searchQuery,
        category: category,
      );

    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            tooltip: 'Wishlist',
            icon: const Icon(Icons.favorite_border_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wishlist coming soon')),
              );
            },
          ),
        ],
      ),
      body: _ProductCatalogBody(
        searchQuery: searchQuery,
        category: category,
      ),
    );
  }
}

class _ProductCatalogBody extends StatefulWidget {
  final String searchQuery;
  final String? category;

  const _ProductCatalogBody({
    required this.searchQuery,
    this.category,
  });

  @override
  State<_ProductCatalogBody> createState() => _ProductCatalogBodyState();
}

class _ProductCatalogBodyState extends State<_ProductCatalogBody> {
  final ProductService _productService = ProductService();
  int _refreshToken = 0;

  bool _matchesFilters(Product p) {
    final q = widget.searchQuery.trim().toLowerCase();
    final cat = widget.category?.trim().toLowerCase();

    final matchesQuery = q.isEmpty ||
        p.title.toLowerCase().contains(q) ||
        p.game.toLowerCase().contains(q) ||
        p.accountName.toLowerCase().contains(q) ||
        p.description.toLowerCase().contains(q);

    final matchesCategory =
        cat == null ||
        cat.isEmpty ||
        cat == 'all' ||
        p.game.toLowerCase() == cat ||
        p.tags.map((t) => t.toLowerCase()).contains(cat);

    return matchesQuery && matchesCategory;
  }

  @override
  Widget build(BuildContext context) {
    // Keep existing behavior (may trigger rebuilds based on auth changes)
    context.watch<AuthProvider>();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _refreshToken++);
      },
      child: Builder(
        builder: (context) {
          final stream = _productService.getAllProducts();

          return StreamBuilder<List<Product>>(
            key: ValueKey(_refreshToken),
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoading();
              }

              if (snapshot.hasError) {
                return MarketplaceErrorState(
                  message: snapshot.error.toString(),
                  onRetry: () => setState(() => _refreshToken++),
                );
              }

              final products =
                  (snapshot.data ?? []).where(_matchesFilters).toList();

              if (products.isEmpty) {
                return MarketplaceEmptyState(
                  title: 'No products available',
                  subtitle: 'Try pulling to refresh or change your filters.',
                  onRefresh: () => setState(() => _refreshToken++),
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.66,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];

                          return MarketplaceProductCard(
                            product: product,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => detail
                                      .ProductDetailScreenRedesigned(
                                    product: product,
                                  ),
                                ),
                              );
                            },
                            onFavorite: () async {
                              final auth = context.read<AuthProvider>();
                              final userId = auth.currentUser?.id ?? '';
                              if (userId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please login to use favorites.'),
                                  ),
                                );
                                return;
                              }

                              final favoriteDoc = FirebaseFirestore.instance
                                  .collection('favorites')
                                  .doc(userId)
                                  .collection('items')
                                  .doc(product.id);

                              final doc = await favoriteDoc.get();
                              final isNowFavorite = !doc.exists;

                              if (isNowFavorite) {
                                await favoriteDoc.set({});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã thêm vào danh sách Favorites'),
                                  ),
                                );
                              } else {
                                await favoriteDoc.delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã gỡ khỏi danh sách Favorites'),
                                  ),
                                );
                              }

                              // Refresh to update heart state
                              setState(() => _refreshToken++);
                            },
                            isFavorite: false,
                          );
                        },
                        childCount: products.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.66,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: 8,
      itemBuilder: (context, i) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1 / 1,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: MarketplaceShimmerSkeleton(
                    height: double.infinity,
                    width: double.infinity,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarketplaceShimmerSkeleton(
                      height: 16,
                      width: double.infinity,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(8)),
                    ),
                    const SizedBox(height: 6),
                    MarketplaceShimmerSkeleton(
                      height: 12,
                      width: 80,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(8)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MarketplaceShimmerSkeleton(
                          height: 20,
                          width: 60,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                        ),
                        MarketplaceShimmerSkeleton(
                          height: 20,
                          width: 40,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(999)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

