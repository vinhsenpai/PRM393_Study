import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/cart_provider.dart';
import 'chat_screen.dart';

class AccountDetailScreen extends StatelessWidget {
  final GameAccount account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(title: const Text('Detail')),
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
                          ),
                        ),
                      ),
                      _buildStatusBadge(account.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(account.price),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Game Info'),
                  _buildInfoRow('Game', account.gameName),
                  _buildInfoRow('Seller', account.sellerName),
                  const Divider(height: 32),
                  _buildSectionTitle('Specifications'),
                  ...account.specs.entries.map(
                    (e) => _buildInfoRow(e.key, e.value),
                  ),
                  const Divider(height: 32),
                  _buildSectionTitle('Description'),
                  Text(
                    account.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 100), // Space for bottom buttons
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
          placeholder: (context, url) => Container(color: Colors.grey[200]),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AccountStatus status) {
    Color color = status == AccountStatus.available ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatScreen.otherUser(otherUser: account.sellerName),
                  ),
                );
              },
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Contact'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isAvailable
                  ? () {
                      context.read<CartProvider>().addItem(account);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to cart')),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isAvailable
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
              child: Text(isAvailable ? 'Add to Cart' : 'Not Available'),
            ),
          ),
        ],
      ),
    );
  }
}