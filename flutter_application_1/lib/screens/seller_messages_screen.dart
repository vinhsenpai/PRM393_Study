import 'package:flutter/material.dart';
import '../screens/chat_screen.dart';
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
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      // In a real implementation, we would query the chats collection
      // For now, we'll use dummy data
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isLoading = false;
        _conversations = List.generate(5, (index) => {
          'id': 'chat_${index + 1}_${
            widget.sellerId
          }', // This would be the actual chatId
          'buyerId': 'u1', // Hardcoded for demo
          'buyerName': 'Buyer ${index + 1}',
          'lastMessage': 'Interest in your product listing #${index + 1}',
          'timestamp': DateTime.now().subtract(Duration(hours: index * 2)),
          'unreadCount': index % 3,
          'productId': 'product_${index + 1}',
          'productTitle': 'Game Account ${index + 1}',
        });
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversations: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations.where((conv) {
      final buyerName = conv['buyerName'] as String;
      final lastMessage = conv['lastMessage'] as String;
      return buyerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _loadConversations,
              child: _filteredConversations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _filteredConversations.length,
                      itemBuilder: (context, index) {
                        final conv = _filteredConversations[index];
                        return ConversationTile(
                          leadingText: conv['buyerName'] as String,
                          subtitleText: conv['lastMessage'] as String,
                          trailingText: DateFormat.jm().format(
                            conv['timestamp'] as DateTime,
                          ),
                          unreadCount: conv['unreadCount'] as int,
                          onTap: () {
                            // Navigate to chat screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen.otherUser(
                                  otherUser: conv['buyerName'] as String,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadConversations,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.refresh),
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
            'Start chatting with buyers who are interested in your products',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // In a real app, this might navigate to a "buyers" screen
              // For now, just show a message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Buyer list would appear here in a full implementation'),
                ),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Find Buyers'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}