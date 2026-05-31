import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';

class PurchasedItemsScreen extends StatelessWidget {
  const PurchasedItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    // Mock data for purchased items
    final purchasedItems = [
      GameAccount.dummyAccounts[2], // PUBG Mobile Account (Sold)
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('My Purchases')),
      body: purchasedItems.isEmpty
          ? const Center(child: Text('You haven\'t bought anything yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: purchasedItems.length,
              itemBuilder: (context, index) {
                final account = purchasedItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            account.imageUrls.first,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bought from: ${account.sellerName}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currencyFormat.format(account.price),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.verified, color: Colors.green),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
