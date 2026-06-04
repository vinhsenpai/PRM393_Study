import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/product_service.dart';
import '../services/chat_service.dart';
import '../screens/create_listing_screen.dart';
import '../screens/edit_listing_screen.dart';
import '../screens/seller_messages_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/conversation_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerDashboardScreen extends StatefulWidget {
  final String sellerId;

  const SellerDashboardScreen({super.key, required this.sellerId});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final ProductService _productService = ProductService();
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateListingScreen(sellerId: widget.sellerId),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.value(), // Refresh handled by streams
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards using Streams
              StreamBuilder<List<Product>>(
                stream: _productService.getProductsBySeller(widget.sellerId),
                builder: (context, productSnapshot) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _chatService.getChatsForUser(widget.sellerId),
                    builder: (context, chatSnapshot) {
                      // Calculate stats
                      int totalProducts = productSnapshot.data?.length ?? 0;
                      int activeListings = 0;
                      bool hasProductData = productSnapshot.data != null;
                      if (hasProductData) {
                        activeListings = productSnapshot.data!
                            .where((p) => p.stockStatus == ProductStatus.available)
                            .length;
                      }
                      int totalConversations =
                          chatSnapshot.data?.length ?? 0;
                      
                      return Row(
                        children: [
                          _buildStatCard(
                            'Total Products',
                            totalProducts.toString(),
                            Icons.inventory,
                            AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            'Active Listings',
                            activeListings.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            'Conversations',
                            totalConversations.toString(),
                            Icons.chat_bubble,
                            Colors.orange,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      Icons.add_circle_outline,
                      'New Listing',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateListingScreen(sellerId: widget.sellerId),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionButton(
                      Icons.message_outlined,
                      'Messages',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellerMessagesScreen(sellerId: widget.sellerId),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Recent Products
              const Text(
                'Recent Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<Product>>(
                stream: _productService.getProductsBySeller(widget.sellerId)
                    .map((products) => products.take(4).toList()), // Show last 4
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No products yet'));
                  }
                  return SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: snapshot.data![index],
                          onTap: () {
                            // Navigate to edit product
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditListingScreen(
                                  sellerId: widget.sellerId,
                                  productId: snapshot.data![index].id,
                                  initialProduct: snapshot.data![index],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Recent Conversations
              const Text(
                'Recent Conversations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chatService.getChatsForUser(widget.sellerId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No conversations yet'));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final conv = snapshot.data![index];
                      return ConversationTile(
                        leadingText: conv['buyerName'] ?? 'Unknown Buyer',
                        subtitleText: conv['lastMessage'] ?? 'No messages',
                        trailingText: DateFormat.jm().format(
                          (conv['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                        ),
                        unreadCount: 0, // We'd need to calculate this properly
                        onTap: () {
                          // Navigate to chat screen
                          // We would need the actual chatId and product info here
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}