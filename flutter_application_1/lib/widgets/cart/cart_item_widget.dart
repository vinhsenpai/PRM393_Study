import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/cart_item.dart';


class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = _currencyFormat(context);

    final imageUrl = item.imageUrl.isNotEmpty ? item.imageUrl : null;

    return Dismissible(
      key: ValueKey(item.productId),
      direction: DismissDirection.endToStart,
      background: _dismissBg(),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Remove item?'),
                content: Text('Remove "${item.title}" from your cart?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onRemove(),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl == null
                    ? Container(
                        width: 76,
                        height: 76,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined),
                      )
                    : Image.network(
                        imageUrl,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 76,
                            height: 76,
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          );
                        },
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormat.format(item.price),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _QuantityStepper(
                          quantity: item.quantity,
                          onIncrement: onIncrement,
                          onDecrement: onDecrement,
                        ),
                        const Spacer(),
                        Text(
                          currencyFormat.format(item.price * item.quantity),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onRemove,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove'),
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

  Widget _dismissBg() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      child: const Icon(Icons.delete_outline, color: Colors.redAccent),
    );
  }

  NumberFormat _currencyFormat(BuildContext context) {
    // Keep consistent with existing cart screen.
    // Locale 'vi_VN' and symbol '₫'.
    // Import locally to avoid extra top-level imports.
    // ignore: deprecated_member_use
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease',
            onPressed: quantity <= 1 ? null : onDecrement,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            tooltip: 'Increase',
            onPressed: onIncrement,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

