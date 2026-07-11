import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _placeOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final cartProvider = context.read<CartProvider>();
    final orderService = OrderService();

    try {
      // Convert cart items to the format expected by order service
      final List<Map<String, dynamic>> cartItems = [];
      cartProvider.items.forEach((productId, cartItem) {
        cartItems.add({
          'productId': productId,
          'title': cartItem.title,
          'price': cartItem.price,
          'quantity': cartItem.quantity,
          'imageUrl': cartItem.imageUrl,
          'sellerId': cartItem.sellerId, // Needed for order service to get sellerId
        });
      });

      final orderId = await orderService.createOrder(cartItems);
      await cartProvider.clearCart();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(orderId: orderId),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $_error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final items = cartProvider.items.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Buyer Information Section
                _BuyerInformationSection(),

                const Divider(height: 1),

                // Cart Items Section
                if (items.isEmpty)
                  _EmptyCartMessage()
                else
                  _CartItemsSection(items: items),

                const Divider(height: 1),

                // Order Summary Section
                _OrderSummarySection(
                  items: items,
                  subtotal: cartProvider.totalPrice,
                ),

                const Divider(height: 1),

                // Payment Method Section (Placeholder)
                _PaymentMethodSection(),

                const SizedBox(height: 24),

                // Place Order Button
                _PlaceOrderButton(
                  onPressed: _placeOrder,
                  isLoading: _isLoading,
                ),
              ],
            ),
    );
  }
}

class _BuyerInformationSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Buyer Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // In a real app, we would get user details from auth or profile
          // For now, we'll show placeholder information
          const Text(
            'Name: John Doe',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Email: john.doe@example.com',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Phone: +1 (555) 123-4567',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _EmptyCartMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to proceed with checkout',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemsSection extends StatelessWidget {
  final List<CartItem> items;

  const _CartItemsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items in Cart',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _CartItemTile(item: item);
            },
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Product Image
          SizedBox(
            width: 80,
            height: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported, size: 40),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 40),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Game: ${item.game}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Price: ',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Quantity Controls
          Column(
            children: [
              IconButton(
                onPressed: () {
                  // This would be handled by the CartProvider in a real implementation
                  // For now, we'll just show a toast or do nothing
                },
                icon: const Icon(Icons.remove),
              ),
              Text(
                '${item.quantity}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                onPressed: () {
                  // Similarly, this would call updateQuantity
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          // Remove Button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              // In a real app, we would call cartProvider.removeFromCart(item.productId)
              // For now, we'll just show a snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item removed from cart')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OrderSummarySection extends StatelessWidget {
  final List<CartItem> items;
  final double subtotal;

  const _OrderSummarySection({
    required this.items,
    required this.subtotal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Items count
          Text(
            '${items.length} item${items.length > 1 ? 's' : ''}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal:',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '\$${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Total (same as subtotal since no tax/shipping in this example)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Placeholder for payment method selection
          ListTile(
            leading: Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary),
            title: const Text('Credit/Debit Card'),
            subtitle: const Text('**** **** **** 1234'),
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.paypal, color: Theme.of(context).colorScheme.primary),
            title: const Text('PayPal'),
            subtitle: const Text('linked to paypal@example.com'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _PlaceOrderButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _PlaceOrderButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Place Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}