import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/navigation/buyer_bottom_nav.dart';
import '../screens/buyer_home_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/order_history_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/notifications_screen.dart';

class BuyerNavigationShell extends StatefulWidget {
  static final GlobalKey<BuyerNavigationShellState> navKey = GlobalKey<BuyerNavigationShellState>();

  const BuyerNavigationShell({super.key});

  @override
  State<BuyerNavigationShell> createState() => BuyerNavigationShellState();
}

class BuyerNavigationShellState extends State<BuyerNavigationShell> {
  int _currentIndex = 0;

  void setSelectedIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id ?? '';

    final List<Widget> pages = [
      const BuyerHomeScreen(),
      const CartScreen(),
      const OrderHistoryScreen(),
      const NotificationsScreen(),
      FavoritesScreen(userId: userId),
      ProfileScreen(userId: userId),
    ];

    void onItemTapped(int index) {
      setSelectedIndex(index);
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BuyerBottomNav(
        currentIndex: _currentIndex,
        onTap: onItemTapped,
      ),
    );
  }
}