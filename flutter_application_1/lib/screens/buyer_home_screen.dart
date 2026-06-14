import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/product_catalog_screen.dart';
import 'cart_screen.dart';

class BuyerHomeScreen extends StatelessWidget {
  const BuyerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GameAcctHub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          _buildHero(),
          Expanded(
            child: const ProductCatalogScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Find your dream game account today.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('User'),
            accountEmail: const Text(''),
            currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('My Orders'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Wishlist'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
    );
  }
}

