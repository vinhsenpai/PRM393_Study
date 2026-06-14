import 'package:flutter/material.dart';

class StickyProductActionBar extends StatelessWidget {
  final VoidCallback onContact;
  final VoidCallback onBuyNow;
  final VoidCallback onAddToCart;

  const StickyProductActionBar({
    super.key,
    required this.onContact,
    required this.onBuyNow,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onContact,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Contact'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onBuyNow,
                  child: const Text('Buy Now'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onAddToCart,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_shopping_cart_outlined),
                tooltip: 'Add to cart',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

