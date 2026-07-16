import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/account_card.dart';
import 'cart_screen.dart';
import 'seller_dashboard_screen.dart';
import 'admin_dashboard_screen.dart';

class AccountListScreen extends StatelessWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('GameAcctHub'),
        actions: [
          if (!auth.isAdmin) // Admins don't usually shop
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(radius: 30, child: Icon(Icons.person)),
                  const SizedBox(height: 12),
                  Text(
                    'Hello, ${auth.currentUser?.name ?? 'User'}!',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    auth.currentUser?.role.name.toUpperCase() ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Browse Accounts'),
              onTap: () => Navigator.pop(context),
            ),
            if (auth.isSeller || auth.isAdmin)
              ListTile(
                leading: const Icon(Icons.dashboard_customize_outlined),
                title: const Text('Seller Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SellerDashboardScreen(),
                    ),
                  );
                },
              ),
            if (auth.isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen(),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Order History'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.notifications_none),
              title: const Text('Notifications'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                context.read<AuthProvider>().logout();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          _buildFilters(context),
          Expanded(
            child: Consumer<AccountProvider>(
              builder: (context, provider, child) {
                final accounts = provider.accounts;
                if (accounts.isEmpty) {
                  return const Center(child: Text('No accounts found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    return AccountCard(account: accounts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        style: const TextStyle(color: Color(0xFF0F172A)),
        cursorColor: Theme.of(context).primaryColor,
        decoration: InputDecoration(
          hintText: 'Search for accounts or games...',
          hintStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          context.read<AccountProvider>().updateSearch(value);
        },
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final provider = context.watch<AccountProvider>();
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: provider.availableGames.map((game) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(game),
              selected:
                  (provider.availableGames.indexOf(game) == 0 &&
                      provider.accounts.isEmpty) ||
                  false, // Simplified for demo
              onSelected: (selected) {
                provider.updateFilters(game: game);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
