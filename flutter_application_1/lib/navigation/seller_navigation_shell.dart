import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/navigation/seller_bottom_nav.dart';
import '../screens/seller_dashboard_screen.dart';
import '../screens/seller_products_screen.dart';
import '../screens/seller_orders_screen.dart';
import '../screens/seller_analytics_screen.dart';
import '../screens/seller_profile_screen.dart';
import '../screens/notifications_screen.dart';

class SellerNavigationShell extends StatefulWidget {
  static final GlobalKey<SellerNavigationShellState> navKey = GlobalKey<SellerNavigationShellState>();

  const SellerNavigationShell({super.key});

  @override
  State<SellerNavigationShell> createState() => SellerNavigationShellState();
}

class SellerNavigationShellState extends State<SellerNavigationShell> {
  int _currentIndex = 0;

  void setSelectedIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final sellerId = auth.currentUser?.id ?? '';

    final List<Widget> pages = [
      SellerDashboardScreen(sellerId: sellerId),
      SellerProductsScreen(sellerId: sellerId),
      SellerOrdersScreen(sellerId: sellerId),
      const NotificationsScreen(),
      SellerAnalyticsScreen(),
      SellerProfileScreen(),
    ];

    void onItemTapped(int index) {
      setSelectedIndex(index);
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