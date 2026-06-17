import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/navigation/seller_bottom_nav.dart';
import '../screens/seller_dashboard_screen.dart';
import '../screens/order_history_screen.dart';

class SellerNavigationShell extends StatefulWidget {
  const SellerNavigationShell({super.key});

  @override
  State<SellerNavigationShell> createState() => _SellerNavigationShellState();
}

class _SellerNavigationShellState extends State<SellerNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const SellerDashboardScreen(),
    const Center(child: Text('Products Screen - Coming Soon')),
    const OrderHistoryScreen(), // TODO: Filter for seller's orders
    const Center(child: Text('Analytics Screen - Coming Soon')),
    const Center(child: Text('Profile Screen - Coming Soon')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SellerBottomNav(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}