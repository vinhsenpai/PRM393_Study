import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../services/product_service.dart';
import '../widgets/marketplace/marketplace_product_card.dart';
import '../widgets/marketplace/marketplace_widgets.dart';

// Backward compatible alias: the catalog screen previously referenced a widget
// named `ProductDetailScreen`. This project uses `ProductDetailScreenRedesigned`.
import 'product_detail_screen_redesigned.dart' as detail;

class ProductCatalogScreen extends StatelessWidget {
  final bool hideAppBar;

  const ProductCatalogScreen({super.key, this.hideAppBar = false});

  @override
  Widget build(BuildContext context) {
    if (hideAppBar) {
      return const _ProductCatalogBody();
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
      body: const _ProductCatalogBody(),
    );
  }
}

class _ProductCatalogBody extends StatefulWidget {
  const _ProductCatalogBody();

  @override
  State<_ProductCatalogBody> createState() => _ProductCatalogBodyState();
}

class _ProductCatalogBodyState extends State<_ProductCatalogBody> {
  final ProductService _productService = ProductService();
  int _refreshToken = 0;

  @override
  Widget build(BuildContext context) {
    // Keeps existing behavior (even if not used directly, it might trigger rebuilds)
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

              final products = snapshot.data ?? [];

              if (products.isEmpty) {
                return MarketplaceEmptyState(
                  title: 'No products available',
                  subtitle: 'Try pulling to refresh or come back later.',
                  onRefresh: () => setState(() => _refreshToken++),
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                            onFavorite: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Favorites coming soon'),
                                ),
                              );
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    const SizedBox(height: 6),
                    MarketplaceShimmerSkeleton(
                      height: 12,
                      width: 80,
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MarketplaceShimmerSkeleton(
                          height: 20,
                          width: 60,
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                        ),
                        MarketplaceShimmerSkeleton(
                          height: 20,
                          width: 40,
                          borderRadius: const BorderRadius.all(Radius.circular(999)),
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

