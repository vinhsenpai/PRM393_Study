import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/account_provider.dart';

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountProvider>();
    final sellerAccounts = provider.accounts; // Simplified for demo
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: sellerAccounts.isEmpty
          ? const Center(child: Text('You have no listings yet.'))
          : ListView.builder(
              itemCount: sellerAccounts.length,
              itemBuilder: (context, index) {
                final account = sellerAccounts[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Image.network(account.imageUrls.first, width: 50, height: 50, fit: BoxFit.cover),
                    title: Text(account.title),
                    subtitle: Text(currencyFormat.format(account.price)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open add form
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
