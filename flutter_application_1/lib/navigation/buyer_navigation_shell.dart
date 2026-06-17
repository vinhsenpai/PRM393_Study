import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/navigation/buyer_bottom_nav.dart';
import '../screens/buyer_home_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/order_history_screen.dart';

class BuyerNavigationShell extends StatefulWidget {
  const BuyerNavigationShell({super.key});

  @override
  State<BuyerNavigationShell> createState() => _BuyerNavigationShellState();
}

class _BuyerNavigationShellState extends State<BuyerNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const BuyerHomeScreen(),
    const CartScreen(),
    const OrderHistoryScreen(),
    const Center(child: Text('Favorites Screen - Coming Soon')),
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
      bottomNavigationBar: BuyerBottomNav(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}