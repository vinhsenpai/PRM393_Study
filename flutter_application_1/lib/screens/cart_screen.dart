import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../widgets/cart/cart_item_widget.dart';
import '../widgets/cart/empty_cart_state.dart';
import '../widgets/cart/order_summary_bar.dart';
import '../screens/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<CartProvider>().loadCart();
        },
        child: cart.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 260),
                  EmptyCartState(),
                ],
              )
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 96),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final items = cart.items.values.toList();
                          final item = items[index];

                          return CartItemWidget(
                            item: item,
                            onRemove: () async {
                              await context.read<CartProvider>().removeFromCart(item.productId);
                            },
                            onIncrement: () async {
                              await context.read<CartProvider>().changeQuantityBy(item.productId, 1);
                            },
                            onDecrement: () async {
                              await context.read<CartProvider>().changeQuantityBy(item.productId, -1);
                            },
                          );
                        },
                        childCount: cart.items.length,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: cart.isEmpty
          ? const SizedBox.shrink()
          : OrderSummaryBar(
              totalItems: cart.totalItems,
              totalPrice: cart.totalPrice,
              onCheckout: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CheckoutScreen(),
                  ),
                );
              },
            ),
    );
  }
}