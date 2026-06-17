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
      child: SizedBox(
        width: 140,
        height: 200,
        child: Container(
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
              SizedBox(
                height: 72,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: product.imageUrls.isNotEmpty
                      ? Image.network(
                          product.imageUrls.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[300]!,
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Color(0xFF6B6B6B),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300]!,
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Color(0xFF6B6B6B),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300]!,
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Color(0xFF6B6B6B),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${product.price.toStringAsFixed(0)} đ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
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
            ],
          ),
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

