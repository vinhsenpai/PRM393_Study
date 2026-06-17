import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../services/order_service.dart';
import '../widgets/shared/order_summary_card.dart';
import '../widgets/shared/search_filter_bar.dart';
import '../widgets/seller/order_card.dart';
import '../widgets/shared/empty_state.dart';
import '../widgets/shared/skeleton_loader.dart';
import 'seller_order_detail_screen.dart';

class SellerOrdersScreen extends StatefulWidget {
  final String sellerId;

  const SellerOrdersScreen({Key? key, required this.sellerId}) : super(key: key);

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Pending, Processing, Completed, Cancelled
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MarketplaceOrder> _filterOrders(List<MarketplaceOrder> orders) {
    // First, filter by search query
    final List<MarketplaceOrder> searchedOrders = orders.where((order) {
      final lowerQuery = _searchQuery.toLowerCase();
      return order.orderId.toLowerCase().contains(lowerQuery) ||
             order.buyerName.toLowerCase().contains(lowerQuery) ||
             order.buyerEmail.toLowerCase().contains(lowerQuery) ||
             order.items.any((item) =>
                 item.title.toLowerCase().contains(lowerQuery));
    }).toList();

    // Then, filter by status if not 'All'
    if (_selectedFilter == 'All') {
      return searchedOrders;
    }
    return searchedOrders.where((order) => order.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return 2;
    } else if (screenWidth >= 600) {
      return 4;
    }
    return 3; // for screens between 400 and 600
  }

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        elevation: 0,
      ),
      body: StreamBuilder<List<MarketplaceOrder>>(
        stream: orderService.getOrdersBySeller(widget.sellerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonLoader(
              type: SkeletonLoaderType.ordersList,
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final orders = snapshot.data ?? [];
          final filteredOrders = _filterOrders(orders);

          // Calculate summary stats
          final pendingCount = orders.where((o) => o.status == 'pending').length;
          final processingCount = orders.where((o) => o.status == 'processing').length;
          final completedCount = orders.where((o) => o.status == 'completed').length;
          final revenue = orders
              .where((o) => o.status == 'completed')
              .fold(0.0, (sum, order) => sum + order.totalAmount);

          // Build summary cards
          final List<Widget> summaryCards = [
            OrderSummaryCard(
              title: 'Pending Orders',
              value: pendingCount.toString(),
              color: Colors.orange,
              icon: Icons.pending_actions,
            ),
            OrderSummaryCard(
              title: 'Processing Orders',
              value: processingCount.toString(),
              color: Colors.blue,
              icon: Icons.timer,
            ),
            OrderSummaryCard(
              title: 'Completed Orders',
              value: completedCount.toString(),
              color: Colors.green,
              icon: Icons.check_circle,
            ),
            OrderSummaryCard(
              title: 'Revenue',
              value: '\$${revenue.toStringAsFixed(2)}',
              color: Colors.green,
              icon: Icons.attach_money,
            ),
          ];

          return CustomScrollView(
            slivers: [
              // Summary Cards - Responsive Grid
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(context),
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => summaryCards[index],
                    childCount: summaryCards.length,
                  ),
                ),
              ),
              // Search and Filter Bar
              SliverToBoxAdapter(
                child: SearchFilterBar(
                  searchController: _searchController,
                  onSearchChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                  },
                  onFilterChanged: (filter) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  selectedFilter: _selectedFilter,
                ),
              ),
              // Orders List
              if (filteredOrders.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    message: 'No orders yet',
                    subMessage: 'Orders will appear here when buyers purchase your products',
                    icon: Icons.shopping_bag_outlined,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = filteredOrders[index];
                      return OrderCard(
                        order: order,
                        onTap: () {
                          // Navigate to order detail screen
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SellerOrderDetailScreen(
                                orderId: order.orderId,
                              ),
                            ),
                          );
                        },
                        onAccept: () {
                          if (order.status == 'pending') {
                            _updateOrderStatus(order.orderId, 'processing');
                          }
                        },
                        onCancel: () {
                          if (order.status == 'pending' || order.status == 'processing') {
                            _updateOrderStatus(order.orderId, 'cancelled');
                          }
                        },
                        onMarkCompleted: () {
                          if (order.status == 'processing') {
                            _updateOrderStatus(order.orderId, 'completed');
                          }
                        },
                      );
                    },
                    childCount: filteredOrders.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
            'status': newStatus,
            'updatedAt': Timestamp.now(),
          });

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.sellerOrdersCapitalize()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Extension to capitalize first letter - unique to avoid conflicts
extension SellerOrdersStringExtension on String {
  String sellerOrdersCapitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}