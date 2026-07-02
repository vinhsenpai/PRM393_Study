import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/chat_screen.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/conversation_tile.dart';
import 'package:intl/intl.dart';

class SellerMessagesScreen extends StatefulWidget {
  final String sellerId;

  const SellerMessagesScreen({super.key, required this.sellerId});

  @override
  State<SellerMessagesScreen> createState() => _SellerMessagesScreenState();
}

class _SellerMessagesScreenState extends State<SellerMessagesScreen> {
  final ChatService _chatService = ChatService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
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
                hintText: 'Search conversations...',
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
        stream: _chatService.getChatsForUser(widget.sellerId),
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
            final buyerName = (chat['buyerName'] as String? ?? '').toLowerCase();
            final lastMessage = (chat['lastMessage'] as String? ?? '').toLowerCase();
            final productTitle = (chat['productTitle'] as String? ?? '').toLowerCase();
            final query = _searchQuery.toLowerCase();
            return buyerName.contains(query) || lastMessage.contains(query) || productTitle.contains(query);
          }).toList();

          if (filteredChats.isEmpty) {
            return const Center(child: Text('No matching conversations found.'));
          }

          return ListView.builder(
            itemCount: filteredChats.length,
            itemBuilder: (context, index) {
              final chat = filteredChats[index];
              final buyerId = chat['buyerId'] ?? '';
              final buyerName = chat['buyerName'] as String? ?? '';
              final lastMsg = chat['lastMessage'] ?? 'No messages yet';
              final productTitle = chat['productTitle'] ?? 'Product';
              
              DateTime updatedAt = DateTime.now();
              if (chat['updatedAt'] is Timestamp) {
                updatedAt = (chat['updatedAt'] as Timestamp).toDate();
              }

              return BuyerConversationTile(
                chat: chat,
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
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conversations with interested buyers will appear here.',
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
class BuyerConversationTile extends StatefulWidget {
  final Map<String, dynamic> chat;
  final String buyerId;
  final String buyerName;
  final String lastMsg;
  final String productTitle;
  final DateTime updatedAt;

  const BuyerConversationTile({
    super.key,
    required this.chat,
    required this.buyerId,
    required this.buyerName,
    required this.lastMsg,
    required this.productTitle,
    required this.updatedAt,
  });

  @override
  State<BuyerConversationTile> createState() => _BuyerConversationTileState();
}

class _BuyerConversationTileState extends State<BuyerConversationTile> {
  late Future<DocumentSnapshot> _fetchUserFuture;

  @override
  void initState() {
    super.initState();
    // Khởi tạo Future đúng 1 lần duy nhất trong initState để tránh tạo Future liên tục khi build
    _fetchUserFuture = FirebaseFirestore.instance.collection('users').doc(widget.buyerId).get();
  }

  @override
  Widget build(BuildContext context) {
    // Nếu buyerName đã hợp lệ và không trống, hiển thị trực tiếp
    if (widget.buyerName.trim().isNotEmpty &&
        widget.buyerName != 'Unknown Buyer' &&
        widget.buyerName != 'No name set') {
      return _buildTile(widget.buyerName);
    }

    // Nếu trống hoặc là tên mặc định, dùng FutureBuilder đã được gán Future cố định
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
      subtitleText: '${widget.productTitle}: ${widget.lastMsg}',
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