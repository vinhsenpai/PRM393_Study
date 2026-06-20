import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/navigation/seller_bottom_nav.dart';
import '../screens/seller_dashboard_screen.dart';
import '../screens/seller_products_screen.dart';
import '../screens/seller_orders_screen.dart';
import '../screens/seller_analytics_screen.dart';
import '../screens/seller_profile_screen.dart';

class SellerNavigationShell extends StatefulWidget {
  const SellerNavigationShell({super.key});

  @override
  State<SellerNavigationShell> createState() => _SellerNavigationShellState();
}

class _SellerNavigationShellState extends State<SellerNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final sellerId = auth.currentUser?.id ?? '';

    final List<Widget> pages = [
      SellerDashboardScreen(sellerId: sellerId),
      SellerProductsScreen(sellerId: sellerId),
      SellerOrdersScreen(sellerId: sellerId),
      SellerAnalyticsScreen(),
      SellerProfileScreen(),
    ];

    void onItemTapped(int index) {
      setState(() {
        _currentIndex = index;
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: SellerBottomNav(
        currentIndex: _currentIndex,
        onTap: onItemTapped,
      ),
    );
  }
}