import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../services/product_service.dart';
import '../widgets/marketplace/marketplace_product_card.dart';
import '../widgets/marketplace/marketplace_widgets.dart';
import 'product_detail_screen_redesigned.dart';

// Backward compatible alias: the catalog screen previously referenced a widget
// named `ProductDetailScreen`. This project uses `ProductDetailScreenRedesigned`.
import 'product_detail_screen_redesigned.dart' as detail;

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final ProductService _productService = ProductService();
  int _refreshToken = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
      body: RefreshIndicator(
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
                      sliver: SliverList.separated(
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return MarketplaceProductCard(
                            product: product,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
builder: (_) => detail.ProductDetailScreenRedesigned(product: product),
                                ),
                              );
                            },
                            onQuickView: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
builder: (_) => detail.ProductDetailScreenRedesigned(product: product),
                                ),
                              );
                            },
                            onFavorite: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Favorites coming soon')),
                              );
                            },
                            isFavorite: false,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: MarketplaceShimmerSkeleton(
                    height: 200,
                    width: double.infinity,
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarketplaceShimmerSkeleton(
                      height: 16,
                      width: MediaQuery.sizeOf(context).width * 0.6,
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    const SizedBox(height: 10),
                    MarketplaceShimmerSkeleton(
                      height: 12,
                      width: MediaQuery.sizeOf(context).width * 0.35,
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        MarketplaceShimmerSkeleton(
                          height: 20,
                          width: MediaQuery.sizeOf(context).width * 0.3,
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                        ),
                        const Spacer(),
                        MarketplaceShimmerSkeleton(
                          height: 22,
                          width: MediaQuery.sizeOf(context).width * 0.22,
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

