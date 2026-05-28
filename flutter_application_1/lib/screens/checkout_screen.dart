import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';
  String _paymentMethod = 'COD';

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...cart.items.values.map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.account.title),
                    trailing: Text(currencyFormat.format(item.account.price)),
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    currencyFormat.format(cart.totalAmount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Please enter your phone' : null,
                onSaved: (value) => _phone = value!,
              ),
              const SizedBox(height: 32),
              const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              RadioListTile(
                title: const Text('Cash on Delivery (COD)'),
                value: 'COD',
                groupValue: _paymentMethod,
                onChanged: (value) => setState(() => _paymentMethod = value.toString()),
              ),
              RadioListTile(
                title: const Text('Fake Gateway (Demo)'),
                value: 'GATEWAY',
                groupValue: _paymentMethod,
                onChanged: (value) => setState(() => _paymentMethod = value.toString()),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _processCheckout();
                    }
                  },
                  child: const Text('Confirm Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processCheckout() {
    // For demo purposes, we just print the contact info
    debugPrint('Processing order for: $_name, Phone: $_phone, Method: $_paymentMethod');
    
    // Clear cart and show success
    context.read<CartProvider>().clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success!'),
        content: const Text('Your order has been placed successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
