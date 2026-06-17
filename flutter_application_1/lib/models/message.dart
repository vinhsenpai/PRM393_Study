import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String text;
  final DateTime createdAt;

  Message({
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory Message.fromDocument(Map<String, dynamic> doc) {
    return Message(
      senderId: doc['senderId'] as String,
      text: doc['text'] as String,
      createdAt: (doc['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}