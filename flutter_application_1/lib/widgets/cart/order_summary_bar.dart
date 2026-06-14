import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/cart_item.dart';


class OrderSummaryBar extends StatelessWidget {
  final int totalItems;
  final double totalPrice;
  final VoidCallback onCheckout;

  const OrderSummaryBar({
    super.key,
    required this.totalItems,
    required this.totalPrice,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, -6),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$totalItems items',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currencyFormat.format(totalPrice),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              child: FilledButton(
                onPressed: onCheckout,
                child: const Text('Checkout'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

