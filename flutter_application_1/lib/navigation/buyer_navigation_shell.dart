import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/navigation/buyer_bottom_nav.dart';
import '../screens/buyer_home_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/order_history_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/profile_screen.dart';

class BuyerNavigationShell extends StatefulWidget {
  const BuyerNavigationShell({super.key});

  @override
  State<BuyerNavigationShell> createState() => _BuyerNavigationShellState();
}

class _BuyerNavigationShellState extends State<BuyerNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id ?? '';

    final List<Widget> _pages = [
      const BuyerHomeScreen(),
      const CartScreen(),
      const OrderHistoryScreen(),
      FavoritesScreen(userId: userId),
      ProfileScreen(userId: userId),
    ];

    void _onItemTapped(int index) {
      setState(() {
        _currentIndex = index;
      });
    }

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