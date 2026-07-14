import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order.dart';
import '../widgets/shared/order_timeline.dart';
import '../widgets/shared/order_detail_section.dart';
import '../widgets/shared/billing_section.dart';
import '../widgets/seller/product_detail_card.dart';

class SellerOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const SellerOrderDetailScreen({super.key, required this.orderId});

  @override
  State<SellerOrderDetailScreen> createState() => _SellerOrderDetailScreenState();
}

class _SellerOrderDetailScreenState extends State<SellerOrderDetailScreen> {
  bool _isLoading = true;
  MarketplaceOrder? _order;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Order not found';
          _isLoading = false;
        });
        return;
      }

      final order = MarketplaceOrder.fromDocument(doc);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading order: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    if (_order == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
            'status': newStatus,
            'updatedAt': Timestamp.now(),
          });

      // Refresh the order
      await _loadOrder();

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.sellerOrderDetailCapitalize()}'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Detail'),
        ),
        body: Center(
          child: Text(_error),
        ),
      );
    }

    final order = _order!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.orderId.substring(0, 8)}...'),
        elevation: 0,
        actions: [
          // Only show edit/delete if order is pending or processing?
          // Based on requirements, we don't have edit/delete in detail screen
          // Only status update actions
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Order Information Section
          SliverToBoxAdapter(
            child: OrderDetailSection(
              title: 'Order Information',
              children: [
                _buildDetailRow('Order ID', order.orderId),
                _buildDetailRow('Status', order.status.sellerOrderDetailCapitalize(),
                    statusColor: _getStatusColor(order.status)),
                _buildDetailRow('Created Date',
                    '${order.createdAt.toDate().day} ${_getMonthName(order.createdAt.toDate().month)} ${order.createdAt.toDate().year}'),
                _buildDetailRow('Updated Date',
                    '${order.updatedAt.toDate().day ?? order.createdAt.toDate().day} ${_getMonthName(order.updatedAt.toDate().month ?? order.createdAt.toDate().month)} ${order.updatedAt.toDate().year ?? order.createdAt.toDate().year}'),
              ],
            ),
          ),
          // Buyer Information Section
          SliverToBoxAdapter(
            child: OrderDetailSection(
              title: 'Buyer Information',
              children: [
                _buildDetailRow('Name', order.buyerName),
                _buildDetailRow('Email', order.buyerEmail),
              ],
            ),
          ),
          // Product Information Section
          SliverToBoxAdapter(
            child: OrderDetailSection(
              title: 'Product Information',
              children: order.items.map((item) =>
                  ProductDetailCard(product: item)
              ).toList(),
            ),
          ),
          // Billing Information Section
          SliverToBoxAdapter(
            child: BillingSection(
              subtotal: order.subtotal,
              tax: order.tax,
              serviceFee: order.serviceFee,
              total: order.totalAmount,
              paymentMethod: order.paymentMethod,
              transactionId:
                  order.paymentInfo['zpTransId']?.toString(),
            ),
          ),
          // Order Timeline
          SliverToBoxAdapter(
            child: OrderTimeline(
              status: order.status,
            ),
          ),
          // Actions Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildActions(order.status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: statusColor != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  )
                : Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(String currentStatus) {
    if (currentStatus == 'pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showAcceptConfirmation(),
              icon: const Icon(Icons.check_circle),
              label: const Text('Accept Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showCancelConfirmation(),
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Order'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );
    } else if (currentStatus == 'processing') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showCompleteConfirmation(),
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showCancelConfirmation(),
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Order'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      );
    } else if (currentStatus == 'completed' || currentStatus == 'cancelled') {
      return Center(
        child: OutlinedButton.icon(
          onPressed: () => {}, // Just view details, already on detail screen
          icon: const Icon(Icons.remove_red_eye),
          label: const Text('View Details'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.grey),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  void _showAcceptConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Order'),
        content: const Text('Are you sure you want to accept this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateOrderStatus('processing');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateOrderStatus('cancelled');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCompleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: const Text('Are you sure you want to mark this order as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateOrderStatus('completed');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Complete'),
          ),
        ],
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

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

// Extension to capitalize first letter - unique to avoid conflicts
extension SellerOrderDetailStringExtension on String {
  String sellerOrderDetailCapitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}