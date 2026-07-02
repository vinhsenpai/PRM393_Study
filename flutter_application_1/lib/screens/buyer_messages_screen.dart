import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/chat_screen.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/conversation_tile.dart';
import 'package:intl/intl.dart';

class BuyerMessagesScreen extends StatefulWidget {
  final String buyerId;

  const BuyerMessagesScreen({super.key, required this.buyerId});

  @override
  State<BuyerMessagesScreen> createState() => _BuyerMessagesScreenState();
}

class _BuyerMessagesScreenState extends State<BuyerMessagesScreen> {
  final ChatService _chatService = ChatService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats'),
        backgroundColor: AppTheme.primaryColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getChatsForUser(widget.buyerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final chats = snapshot.data ?? [];
          
          if (chats.isEmpty) {
            return _buildEmptyState();
          }

          // Filter by search query
          final filteredChats = chats.where((chat) {
            final sellerName = (chat['sellerName'] as String? ?? '').toLowerCase();
            final lastMessage = (chat['lastMessage'] as String? ?? '').toLowerCase();
            final productTitle = (chat['productTitle'] as String? ?? '').toLowerCase();
            final query = _searchQuery.toLowerCase();
            return sellerName.contains(query) || lastMessage.contains(query) || productTitle.contains(query);
          }).toList();

          if (filteredChats.isEmpty) {
            return const Center(child: Text('No matching conversations found.'));
          }

          return ListView.builder(
            itemCount: filteredChats.length,
            itemBuilder: (context, index) {
              final chat = filteredChats[index];
              final sellerName = chat['sellerName'] ?? 'Unknown Seller';
              final lastMsg = chat['lastMessage'] ?? 'No messages yet';
              final productTitle = chat['productTitle'] ?? 'Product';
              
              DateTime updatedAt = DateTime.now();
              if (chat['updatedAt'] is Timestamp) {
                updatedAt = (chat['updatedAt'] as Timestamp).toDate();
              }

              return ConversationTile(
                leadingText: sellerName,
                subtitleText: '$productTitle: $lastMsg',
                trailingText: DateFormat.jm().format(updatedAt),
                unreadCount: 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        buyerId: chat['buyerId'] ?? '',
                        buyerName: chat['buyerName'] ?? 'Buyer',
                        sellerId: chat['sellerId'] ?? '',
                        sellerName: sellerName,
                        productId: chat['productId'] ?? '',
                        productTitle: productTitle,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation from a product detail page.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
