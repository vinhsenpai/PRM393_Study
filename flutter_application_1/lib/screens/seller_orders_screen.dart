import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart' as app_order;
import '../services/order_service.dart';

class SellerOrdersScreen extends StatelessWidget {
  final String sellerId;

  const SellerOrdersScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: StreamBuilder<List<app_order.MarketplaceOrder>>(
        stream: orderService.getOrdersBySeller(sellerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'You have no orders yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Orders will appear here when buyers purchase your products',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: Text('Order #${order.orderId.substring(0, 8)}...'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${order.createdAt.toString().substring(0, 10)}'),
                    Text('Total: \$${order.totalAmount.toStringAsFixed(2)}'),
                  ],
                ),
                trailing: Text(
                  order.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(order.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  // TODO: Navigate to seller order detail screen
                  // For now, we'll use the existing order detail screen but note it checks for buyerId
                  // We'll create a seller order detail screen later.
                },
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}