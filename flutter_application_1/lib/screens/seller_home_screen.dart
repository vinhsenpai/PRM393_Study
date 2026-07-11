import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'seller_dashboard_screen.dart';

class SellerHomeScreen extends StatelessWidget {
  const SellerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Center')),
      drawer: _buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatGrid(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final sellerId = auth.currentUser?.id ?? '';
                if (sellerId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Seller id is not ready yet. Please try again.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SellerDashboardScreen(sellerId: sellerId),
                  ),
                );
              },
              icon: const Icon(Icons.manage_accounts),
              label: const Text('Manage My Listings'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _statCard('Active Items', '12', Colors.blue),
        _statCard('Pending Orders', '3', Colors.orange),
        _statCard('Sold Today', '5', Colors.green),
        _statCard('Total Earnings', '2.5M₫', Colors.purple),
      ],
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Center(child: Text('Seller Portal', style: TextStyle(color: Colors.white, fontSize: 20))),
          ),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Logout'), onTap: () => auth.logout()),
        ],
      ),
    );
  }
}