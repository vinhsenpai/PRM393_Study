import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage(String conversationId, String senderId, String text) async {
    if (text.trim().isEmpty) return;

    final DocumentReference conversationDoc =
        _firestore.collection('conversations').doc(conversationId);
    final CollectionReference messages = conversationDoc.collection('messages');

    await messages.add({
      'senderId': senderId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromDocument(doc.data()))
            .toList());
  }
}