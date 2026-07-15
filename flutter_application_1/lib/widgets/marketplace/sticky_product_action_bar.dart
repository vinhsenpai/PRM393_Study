import 'package:flutter/material.dart';

class StickyProductActionBar extends StatelessWidget {
  final VoidCallback onContact;
  final VoidCallback onBuyNow;
  final VoidCallback onAddToCart;
  final bool isAvailable;

  const StickyProductActionBar({
    super.key,
    required this.onContact,
    required this.onBuyNow,
    required this.onAddToCart,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      color: const Color(0xFF1E293B), // Surface Dark
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF334155), width: 1),
            ),
          ),
          child: Row(
            children: [
              // Contact button
              Expanded(
                child: OutlinedButton(
                  onPressed: onContact,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: Color(0xFF334155)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 18),
                      SizedBox(width: 6),
                      Text('Chat', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Add to Cart button
              IconButton(
                onPressed: isAvailable ? onAddToCart : null,
                icon: const Icon(Icons.add_shopping_cart),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  foregroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.shade900,
                  disabledForegroundColor: Colors.grey.shade600,
                ),
                tooltip: 'Add to cart',
              ),
              const SizedBox(width: 8),

              // Buy Now button - prominent and shiny
              Expanded(
                flex: 2,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: isAvailable
                        ? const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    boxShadow: isAvailable
                        ? [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: isAvailable ? onBuyNow : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.grey.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      isAvailable ? 'Buy Now' : 'Sold Out',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
