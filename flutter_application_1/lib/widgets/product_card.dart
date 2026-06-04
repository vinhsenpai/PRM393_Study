import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.imageUrls.isNotEmpty
                    ? Image.network(
                        product.imageUrls.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: Colors.grey[300]!,
                        width: double.infinity,
                        child: Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey[600]!,
                        ),
                      ),
              ),
            ),
            // Content
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.price.toStringAsFixed(0)} đ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(product.stockStatus)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getStatusColor(product.stockStatus)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        product.stockStatus.toString().split('.').last
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(product.stockStatus),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ProductStatus status) {
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
}