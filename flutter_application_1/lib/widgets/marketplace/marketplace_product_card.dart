import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../theme/app_theme.dart';

class MarketplaceProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onQuickView;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const MarketplaceProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onQuickView,
    this.onFavorite,
    this.isFavorite = false,
  });

  Color _statusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.available:
        return Colors.green;
      case ProductStatus.reserved:
        return Colors.orange;
      case ProductStatus.sold:
        return Colors.red;
      case ProductStatus.hidden:
        return Colors.grey;
    }
  }

  String _statusText(ProductStatus status) =>
      status.toString().split('.').last.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final coverUrl = product.imageUrls.where((e) => e.trim().isNotEmpty).isEmpty
        ? null
        : product.imageUrls.first;

    final statusColor = _statusColor(product.stockStatus);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      if (coverUrl != null)
                        CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, _) => Container(
                            color: Colors.grey.shade200,
                          ),
                          errorWidget: (context, _, __) => Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_not_supported,
                                size: 44, color: Color(0xFF6B6B6B)),
                          ),
                        )
                      else
                        Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported,
                              size: 44, color: Color(0xFF6B6B6B)),
                        ),

                      // Stock badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.35),
                              width: 0.9,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusText(product.stockStatus),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ),

                      // Favorite + quick view
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onFavorite,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.pinkAccent : Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: onQuickView,
                                icon: const Icon(Icons.remove_red_eye_outlined,
                                    size: 18),
                                label: const Text('Quick View'),
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      Colors.black.withValues(alpha: 0.55),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.game,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(0)} đ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      if (product.tags.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            product.tags.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

