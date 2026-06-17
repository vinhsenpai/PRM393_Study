import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  // New constructor with detailed parameters
  final String buyerId;
  final String sellerId;
  final String productId;
  final String productTitle;

  // Old constructor for backward compatibility
  final String? otherUser;

  const ChatScreen({
    super.key,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.productTitle,
  }) : otherUser = null;

  const ChatScreen.otherUser({
    super.key,
    required this.otherUser,
  }) : buyerId = '',
       sellerId = '',
       productId = '',
       productTitle = '';

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController _messageController;
  late final ScrollController _scrollController;
  late final ChatService _chatService;
  late String myId;
  late String myRole;
  late String chatId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final auth = context.read<AuthProvider>();
    myId = auth.currentUser?.id ?? '';
    
    // Handle backward compatibility
    if (widget.otherUser != null) {
      // Old format: just use otherUser as the counterpart
      myRole = 'buyer'; // Assume current user is buyer for simplicity
      // For now, we'll use a simple chat ID based on current user and otherUser
      final List<String> ids = [myId, widget.otherUser!]..where((id) => id.isNotEmpty).toList();
      if (ids.length >= 2) {
        ids.sort();
        chatId = '${ids.first}_${ids.last}';
      } else {
        chatId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
      }
    } else {
      // New format: detailed parameters
      // Determine role based on IDs (in a real app, this would come from user data)
      myRole = (myId == widget.sellerId) ? 'seller' : 'buyer';
      
      // Get or create chat
      chatId = await _chatService.getOrCreateChat(
        widget.buyerId, 
        widget.sellerId, 
        widget.productId
      );
    }
    
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productTitle.isNotEmpty ? widget.productTitle : 'Chat with ${widget.otherUser}'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          // Online indicator for the other user
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.otherUser != null ? 'User Online' : (myRole == 'buyer' ? 'Seller Online' : 'Buyer Online'),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessagesStream(chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isMe = message.senderId == myId;
                    return ChatBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              onSubmitted: (value) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: AppTheme.primaryColor),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text;
    if (text.trim().isNotEmpty) {
      _chatService.sendMessage(
        chatId,
        myId,
        myRole,
        text,
      );
      _messageController.clear();
    }
  }
}