import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../navigation/buyer_navigation_shell.dart';
import 'chat_screen.dart';
import 'checkout_screen.dart';
import '_account_detail_cart_mapping.dart';

class AccountDetailScreen extends StatelessWidget {
  final GameAccount account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Background Dark
      appBar: AppBar(
        title: const Text('Detail'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCarousel(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          account.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF8FAFC),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(account.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(account.price),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF59E0B), // Accent Amber
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Game Info'),
                  _buildInfoRow('Game', account.gameName),
                  _buildInfoRow('Seller', account.sellerName),
                  const Divider(height: 32, color: Color(0xFF334155)),
                  _buildSectionTitle('Specifications'),
                  ...account.specs.entries.map(
                    (e) => _buildInfoRow(e.key, e.value),
                  ),
                  const Divider(height: 32, color: Color(0xFF334155)),
                  _buildSectionTitle('Description'),
                  Text(
                    account.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom actions
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomActions(context),
    );
  }

  Widget _buildImageCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 300,
        viewportFraction: 1.0,
        enlargeCenterPage: false,
        autoPlay: account.imageUrls.length > 1,
      ),
      items: account.imageUrls.map((url) {
        return CachedNetworkImage(
          imageUrl: url,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: const Color(0xFF1E293B),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1)),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: const Color(0xFF1E293B),
            child: const Icon(Icons.sports_esports, size: 50, color: Color(0xFF6366F1)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFF8FAFC),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Color(0xFFF8FAFC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AccountStatus status) {
    Color color;
    switch (status) {
      case AccountStatus.available:
        color = const Color(0xFF10B981);
        break;
      case AccountStatus.reserved:
        color = const Color(0xFFF59E0B);
        break;
      case AccountStatus.sold:
        color = const Color(0xFFEF4444);
        break;
      case AccountStatus.hidden:
        color = const Color(0xFF94A3B8);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final isAvailable = account.status == AccountStatus.available;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(
          top: BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                final buyerId = auth.currentUser?.id ?? '';

                if (buyerId.isEmpty) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please login to contact the seller.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                final rawName = auth.currentUser?.name ?? '';
                final email = auth.currentUser?.email ?? 'Buyer';
                final buyerName =
                    (rawName.trim().isNotEmpty && rawName != 'No name set') ? rawName : email;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      buyerId: buyerId,
                      buyerName: buyerName,
                      sellerId: 'mock_seller_${account.sellerName.replaceAll(' ', '_')}',
                      sellerName: account.sellerName,
                      productId: 'mock_prod_${account.id}',
                      productTitle: account.title,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF8FAFC),
                side: const BorderSide(color: Color(0xFF334155)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 18),
                  SizedBox(width: 6),
                  Text('Chat', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: isAvailable
                ? () async {
                    final cartProvider = context.read<CartProvider>();
                    final mappedProduct = mapGameAccountToProduct(account);
                    await cartProvider.addToCart(mappedProduct);
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF1E293B),
                        duration: const Duration(seconds: 2),
                        content: const Text(
                          'Product added to cart!',
                          style: TextStyle(color: Color(0xFFF8FAFC)),
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF334155)),
                        ),
                        action: SnackBarAction(
                          label: 'VIEW CART',
                          textColor: const Color(0xFF6366F1),
                          onPressed: () {
                            final shellContext = BuyerNavigationShell.navKey.currentContext;
                            if (shellContext != null) {
                              ScaffoldMessenger.of(shellContext).hideCurrentSnackBar();
                              Navigator.of(shellContext).popUntil((route) => route.isFirst);
                              BuyerNavigationShell.navKey.currentState?.setSelectedIndex(1);
                            }
                          },
                        ),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.add_shopping_cart),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF334155),
              foregroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.all(14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: isAvailable
                    ? const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                boxShadow: isAvailable
                    ? [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: isAvailable
                    ? () async {
                        final auth = context.read<AuthProvider>();
                        if (auth.currentUser == null) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please login to buy.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        final cartProvider = context.read<CartProvider>();
                        final mappedProduct = mapGameAccountToProduct(account);
                        await cartProvider.addToCart(mappedProduct);
                        if (!context.mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckoutScreen(),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.grey.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  isAvailable ? 'Buy Now' : 'Sold Out',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}