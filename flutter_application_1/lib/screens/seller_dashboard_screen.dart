import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/chat_service.dart';
import '../screens/create_listing_screen.dart';
import '../screens/edit_listing_screen.dart';
import '../screens/seller_messages_screen.dart';
import '../screens/chat_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/conversation_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerDashboardScreen extends StatefulWidget {
  final String? sellerId;

  const SellerDashboardScreen({super.key, this.sellerId});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final ProductService _productService = ProductService();
  final ChatService _chatService = ChatService();

  String get _sellerIdOrEmpty => widget.sellerId ?? '';

  @override
  Widget build(BuildContext context) {
    final sellerId = _sellerIdOrEmpty;

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
                builder: (_) => CreateListingScreen(sellerId: sellerId),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.value(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<List<Product>>(
                stream: _productService.getProductsBySeller(sellerId),
                builder: (context, productSnapshot) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _chatService.getChatsForUser(sellerId),
                    builder: (context, chatSnapshot) {
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
                          builder: (_) => CreateListingScreen(sellerId: sellerId),
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
                          builder: (_) => SellerMessagesScreen(sellerId: sellerId),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

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
                stream: _productService
                    .getProductsBySeller(sellerId)
                    .map((products) => products.take(4).toList()),
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
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ProductCard(
                            product: snapshot.data![index],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditListingScreen(
                                    sellerId: sellerId,
                                    productId: snapshot.data![index].id,
                                    initialProduct: snapshot.data![index],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

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
                stream: _chatService.getChatsForUser(sellerId),
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
                      final buyerId = conv['buyerId'] ?? '';
                      final buyerName = conv['buyerName'] as String? ?? '';
                      final lastMsg = conv['lastMessage'] ?? 'No messages';
                      final productTitle = conv['productTitle'] ?? 'Product';
                      
                      DateTime updatedAt = DateTime.now();
                      if (conv['updatedAt'] is Timestamp) {
                        updatedAt = (conv['updatedAt'] as Timestamp).toDate();
                      }

                      return DashboardBuyerConversationTile(
                        chat: conv,
                        buyerId: buyerId,
                        buyerName: buyerName,
                        lastMsg: lastMsg,
                        productTitle: productTitle,
                        updatedAt: updatedAt,
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

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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

  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
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

// Widget con để cô lập Future query cho Dashboard tránh Infinite Rebuild Loop
class DashboardBuyerConversationTile extends StatefulWidget {
  final Map<String, dynamic> chat;
  final String buyerId;
  final String buyerName;
  final String lastMsg;
  final String productTitle;
  final DateTime updatedAt;

  const DashboardBuyerConversationTile({
    super.key,
    required this.chat,
    required this.buyerId,
    required this.buyerName,
    required this.lastMsg,
    required this.productTitle,
    required this.updatedAt,
  });

  @override
  State<DashboardBuyerConversationTile> createState() => _DashboardBuyerConversationTileState();
}

class _DashboardBuyerConversationTileState extends State<DashboardBuyerConversationTile> {
  late Future<DocumentSnapshot> _fetchUserFuture;

  @override
  void initState() {
    super.initState();
    _fetchUserFuture = FirebaseFirestore.instance.collection('users').doc(widget.buyerId).get();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.buyerName.trim().isNotEmpty &&
        widget.buyerName != 'Unknown Buyer' &&
        widget.buyerName != 'No name set') {
      return _buildTile(widget.buyerName);
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _fetchUserFuture,
      builder: (context, snapshot) {
        String displayName = widget.buyerName.isEmpty ? 'Buyer' : widget.buyerName;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final name = data?['name'] as String?;
          final email = data?['email'] as String?;
          if (name != null && name.trim().isNotEmpty && name != 'No name set') {
            displayName = name;
          } else if (email != null && email.trim().isNotEmpty) {
            displayName = email;
          }
        }
        return _buildTile(displayName);
      },
    );
  }

  Widget _buildTile(String displayName) {
    return ConversationTile(
      leadingText: displayName,
      subtitleText: widget.lastMsg,
      trailingText: DateFormat.jm().format(widget.updatedAt),
      unreadCount: 0,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              buyerId: widget.buyerId,
              buyerName: displayName,
              sellerId: widget.chat['sellerId'] ?? '',
              sellerName: widget.chat['sellerName'] ?? 'Seller',
              productId: widget.chat['productId'] ?? '',
              productTitle: widget.productTitle,
            ),
          ),
        );
      },
    );
  }
}
