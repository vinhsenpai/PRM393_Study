import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../services/zalopay_service.dart';
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
  String _paymentMethod = 'zalopay_sandbox';

  List<Map<String, dynamic>> _cartItemsPayload(CartProvider cartProvider) {
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
    return cartItems;
  }

  // Must mirror OrderService: total = subtotal + 10% tax + 5% service fee.
  double _orderTotal(CartProvider cartProvider) =>
      cartProvider.totalPrice * 1.15;

  Future<void> _placeOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final cartProvider = context.read<CartProvider>();

    try {
      if (cartProvider.items.isEmpty) {
        throw Exception('Cart is empty');
      }

      if (_paymentMethod == 'zalopay_sandbox') {
        await _payWithZaloPay(cartProvider);
      } else {
        await _completeOrder(cartProvider, paymentMethod: 'cod');
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

  Future<void> _payWithZaloPay(CartProvider cartProvider) async {
    final zaloPayService = ZaloPayService();
    final amountVnd = ZaloPayService.toVndAmount(_orderTotal(cartProvider));

    final zpItems = cartProvider.items.entries
        .map((e) => {
              'itemid': e.key,
              'itemname': e.value.title,
              'itemprice': e.value.price.round(),
              'itemquantity': e.value.quantity,
            })
        .toList();

    // 1. Create the order on the ZaloPay sandbox gateway
    final zpOrder = await zaloPayService.createOrder(
      amountVnd: amountVnd,
      description: 'Marketplace order - ${cartProvider.items.length} item(s)',
      items: zpItems,
    );

    // 2. Open the ZaloPay payment page / sandbox app
    final launched = await launchUrl(
      Uri.parse(zpOrder.orderUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw Exception('Could not open ZaloPay payment page');
    }

    if (!mounted) return;

    // 3. Wait for the buyer to pay, polling the gateway for the result
    final result = await showDialog<ZaloPayQueryResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ZaloPayWaitingDialog(
        service: zaloPayService,
        order: zpOrder,
      ),
    );

    if (!mounted) return;

    if (result == null) {
      // Buyer cancelled while payment was still pending
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment cancelled')),
      );
      return;
    }

    if (result.status != ZaloPayStatus.paid) {
      throw Exception('ZaloPay payment failed: ${result.message}');
    }

    // 4. Payment confirmed — record the order
    await _completeOrder(
      cartProvider,
      paymentMethod: 'zalopay_sandbox',
      paymentInfo: {
        'gateway': 'zalopay_sandbox',
        'appTransId': zpOrder.appTransId,
        'zpTransId': result.zpTransId,
        'amountVnd': result.amount,
        'paidAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> _completeOrder(
    CartProvider cartProvider, {
    required String paymentMethod,
    Map<String, dynamic> paymentInfo = const {},
  }) async {
    final orderService = OrderService();
    final orderId = await orderService.createOrder(
      _cartItemsPayload(cartProvider),
      paymentMethod: paymentMethod,
      paymentInfo: paymentInfo,
    );
    await cartProvider.clearCart();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(orderId: orderId),
        ),
      );
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

                // Payment Method Section
                _PaymentMethodSection(
                  selectedMethod: _paymentMethod,
                  onChanged: (method) =>
                      setState(() => _paymentMethod = method),
                ),

                const SizedBox(height: 24),

                // Place Order Button
                _PlaceOrderButton(
                  onPressed: _placeOrder,
                  isLoading: _isLoading,
                  label: _paymentMethod == 'zalopay_sandbox'
                      ? 'Pay with ZaloPay'
                      : 'Place Order',
                ),
              ],
            ),
    );
  }
}

/// Dialog shown while waiting for the buyer to complete payment in the
/// ZaloPay sandbox app/page. Polls the gateway every few seconds and closes
/// automatically once the payment succeeds or fails.
class _ZaloPayWaitingDialog extends StatefulWidget {
  final ZaloPayService service;
  final ZaloPayOrder order;

  const _ZaloPayWaitingDialog({
    required this.service,
    required this.order,
  });

  @override
  State<_ZaloPayWaitingDialog> createState() => _ZaloPayWaitingDialogState();
}

class _ZaloPayWaitingDialogState extends State<_ZaloPayWaitingDialog> {
  Timer? _pollTimer;
  bool _checking = false;
  String _statusMessage = 'Complete the payment in ZaloPay…';

  static final NumberFormat _vndFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _checkStatus(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (_checking) return;
    _checking = true;
    try {
      final result = await widget.service.queryOrder(widget.order.appTransId);
      if (!mounted) return;
      if (result.status == ZaloPayStatus.pending) {
        setState(() => _statusMessage = 'Waiting for payment confirmation…');
      } else {
        _pollTimer?.cancel();
        Navigator.of(context).pop(result);
      }
    } catch (_) {
      // Network hiccup while polling — keep trying on the next tick.
    } finally {
      _checking = false;
    }
  }

  Future<void> _reopenZaloPay() async {
    await launchUrl(
      Uri.parse(widget.order.orderUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.account_balance_wallet, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text('ZaloPay Sandbox', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _vndFormat.format(widget.order.amountVnd),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Order: ${widget.order.appTransId}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _reopenZaloPay,
          child: const Text('Open ZaloPay'),
        ),
        FilledButton(
          onPressed: _checkStatus,
          child: const Text('Check status'),
        ),
      ],
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
                      NumberFormat.currency(
                              locale: 'vi_VN', symbol: '₫', decimalDigits: 0)
                          .format(item.price),
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
          // Quantity
          Text(
            'x${item.quantity}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  static final NumberFormat _vnd =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    // Must mirror OrderService: 10% tax, 5% service fee
    final tax = subtotal * 0.10;
    final serviceFee = subtotal * 0.05;
    final total = subtotal + tax + serviceFee;

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
          _summaryRow('Subtotal:', _vnd.format(subtotal)),
          const SizedBox(height: 4),
          _summaryRow('Tax (10%):', _vnd.format(tax)),
          const SizedBox(height: 4),
          _summaryRow('Service fee (5%):', _vnd.format(serviceFee)),
          const Divider(height: 16),
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
                _vnd.format(total),
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

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _PaymentMethodSection extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onChanged;

  const _PaymentMethodSection({
    required this.selectedMethod,
    required this.onChanged,
  });

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
          RadioGroup<String>(
            groupValue: selectedMethod,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'zalopay_sandbox',
                  secondary: Icon(
                    Icons.account_balance_wallet,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('ZaloPay (Sandbox)'),
                  subtitle:
                      const Text('Test payment — no real money is charged'),
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  value: 'cod',
                  secondary: Icon(
                    Icons.payments_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Cash on Delivery'),
                  subtitle: const Text('Pay when you receive the order'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceOrderButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String label;

  const _PlaceOrderButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
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
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
