import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or get a chat between buyer and seller for a specific product
  Future<String> getOrCreateChat({
    required String buyerId,
    required String buyerName,
    required String sellerId,
    required String sellerName,
    required String productId,
    required String productTitle,
  }) async {
    // Create chatId in format buyerId_sellerId (sorted to ensure consistency)
    final List<String> ids = [buyerId, sellerId];
    ids.sort();
    final chatId = '${ids.first}_${ids.last}';
    
    // Check if chat already exists
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    
    if (!chatDoc.exists) {
      // Create new chat
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [buyerId, sellerId],
        'buyerId': buyerId,
        'buyerName': buyerName,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'productId': productId,
        'productTitle': productTitle,
        'lastMessage': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    return chatId;
  }

  // Send a message in a chat
  Future<void> sendMessage(String chatId, String senderId, String senderRole, String text) async {
    if (text.trim().isEmpty) return;

    // Add message to messages subcollection
    final DocumentReference chatDoc = _firestore.collection('chats').doc(chatId);
    final CollectionReference messages = chatDoc.collection('messages');
    
    await messages.add({
      'senderId': senderId,
      'senderRole': senderRole, // 'buyer' or 'seller'
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });

    // Update the chat's lastMessage and updatedAt
    await chatDoc.update({
      'lastMessage': text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get messages stream for a chat
  Stream<List<Message>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromDocument(doc.data()))
            .toList());
  }

  // Get chats for a user (buyer or seller)
  Stream<List<Map<String, dynamic>>> getChatsForUser(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .toList());
  }

  // Mark messages as seen
  Future<void> markMessagesAsSeen(String chatId, String userId) async {
    final QuerySnapshot unseenMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('seen', isEqualTo: false)
        .get();
    
    for (final doc in unseenMessages.docs) {
      await doc.reference.update({'seen': true});
    }
  }

  // Get unread count for a user
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((chatSnapshot) async {
      int totalUnread = 0;
      for (final chatDoc in chatSnapshot.docs) {
        final QuerySnapshot unseenMessages = await _firestore
            .collection('chats')
            .doc(chatDoc.id)
            .collection('messages')
            .where('senderId', isNotEqualTo: userId)
            .where('seen', isEqualTo: false)
            .get();
        totalUnread += unseenMessages.size;
      }
      return totalUnread;
    });
  }
}