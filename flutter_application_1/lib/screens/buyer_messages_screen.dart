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
              style: const TextStyle(color: Color(0xFF0F172A)),
              cursorColor: AppTheme.primaryColor,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
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
              final sellerId = chat['sellerId'] ?? '';
              final sellerName = chat['sellerName'] as String? ?? '';
              final lastMsg = chat['lastMessage'] ?? 'No messages yet';
              final productTitle = chat['productTitle'] ?? 'Product';
              
              DateTime updatedAt = DateTime.now();
              if (chat['updatedAt'] is Timestamp) {
                updatedAt = (chat['updatedAt'] as Timestamp).toDate();
              }

              return SellerConversationTile(
                chat: chat,
                sellerId: sellerId,
                sellerName: sellerName,
                lastMsg: lastMsg,
                productTitle: productTitle,
                updatedAt: updatedAt,
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

// Widget con đại diện cho mỗi Tile để cô lập Future và tránh vòng lặp rebuild vô hạn
class SellerConversationTile extends StatefulWidget {
  final Map<String, dynamic> chat;
  final String sellerId;
  final String sellerName;
  final String lastMsg;
  final String productTitle;
  final DateTime updatedAt;

  const SellerConversationTile({
    super.key,
    required this.chat,
    required this.sellerId,
    required this.sellerName,
    required this.lastMsg,
    required this.productTitle,
    required this.updatedAt,
  });

  @override
  State<SellerConversationTile> createState() => _SellerConversationTileState();
}

class _SellerConversationTileState extends State<SellerConversationTile> {
  late Future<DocumentSnapshot> _fetchUserFuture;

  @override
  void initState() {
    super.initState();
    // Khởi tạo Future đúng 1 lần duy nhất trong initState để tránh tạo Future liên tục khi build
    _fetchUserFuture = FirebaseFirestore.instance.collection('users').doc(widget.sellerId).get();
  }

  @override
  Widget build(BuildContext context) {
    // Nếu sellerName đã hợp lệ và không trống, hiển thị trực tiếp
    if (widget.sellerName.trim().isNotEmpty &&
        widget.sellerName != 'Unknown Seller' &&
        widget.sellerName != 'No name set') {
      return _buildTile(widget.sellerName);
    }

    // Nếu trống hoặc là tên mặc định, dùng FutureBuilder đã được gán Future cố định
    return FutureBuilder<DocumentSnapshot>(
      future: _fetchUserFuture,
      builder: (context, snapshot) {
        String displayName = widget.sellerName.isEmpty ? 'Seller' : widget.sellerName;
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
      subtitleText: '${widget.productTitle}: ${widget.lastMsg}',
      trailingText: DateFormat.jm().format(widget.updatedAt),
      unreadCount: 0,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              buyerId: widget.chat['buyerId'] ?? '',
              buyerName: widget.chat['buyerName'] ?? 'Buyer',
              sellerId: widget.sellerId,
              sellerName: displayName,
              productId: widget.chat['productId'] ?? '',
              productTitle: widget.productTitle,
            ),
          ),
        );
      },
    );
  }
}
