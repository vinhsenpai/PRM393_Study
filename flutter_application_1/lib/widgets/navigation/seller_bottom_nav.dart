import 'package:flutter/material.dart';

class SellerBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SellerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      animationDuration: const Duration(milliseconds: 300),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        // Dashboard
        NavigationDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        // Products
        NavigationDestination(
          icon: const Icon(Icons.grid_view_outlined),
          selectedIcon: const Icon(Icons.grid_view),
          label: 'Products',
        ),
        // Orders
        NavigationDestination(
          icon: const Icon(Icons.shopping_bag_outlined),
          selectedIcon: const Icon(Icons.shopping_bag),
          label: 'Orders',
        ),
        // Notifications
        NavigationDestination(
          icon: const Icon(Icons.notifications_none_outlined),
          selectedIcon: const Icon(Icons.notifications_active),
          label: 'Notifications',
        ),
        // Analytics
        NavigationDestination(
          icon: const Icon(Icons.analytics_outlined),
          selectedIcon: const Icon(Icons.analytics),
          label: 'Analytics',
        ),
        // Profile
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
