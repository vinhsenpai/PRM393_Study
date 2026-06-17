import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';

class BuyerBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BuyerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          animationDuration: const Duration(milliseconds: 300),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            // Home
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: 'Home',
            ),
            // Cart with badge
            NavigationDestination(
              icon: Badge(
                label: cart.itemCount > 0
                    ? Text(cart.itemCount.toString())
                    : const Text(''),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              // We don't show selectedIcon for cart because the badge is in the icon
              label: 'Cart',
            ),
            // Orders
            NavigationDestination(
              icon: const Icon(Icons.shopping_bag_outlined),
              selectedIcon: const Icon(Icons.shopping_bag),
              label: 'Orders',
            ),
            // Favorites
            NavigationDestination(
              icon: const Icon(Icons.favorite_border),
              selectedIcon: const Icon(Icons.favorite),
              label: 'Favorites',
            ),
            // Profile
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        );
      },
    );
  }
}