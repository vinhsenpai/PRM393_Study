import 'package:flutter/material.dart';

class EmptyCartState extends StatelessWidget {
  const EmptyCartState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 92,
                color: Colors.black38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Your cart is empty',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add something you love from the marketplace.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Continue Shopping'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

