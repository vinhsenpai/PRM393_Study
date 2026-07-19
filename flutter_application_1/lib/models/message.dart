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
    final rawTimestamp = doc['createdAt'];
    final DateTime timestamp = rawTimestamp is Timestamp
        ? rawTimestamp.toDate()
        : (rawTimestamp is DateTime ? rawTimestamp : DateTime.now());

    return Message(
      senderId: doc['senderId']?.toString() ?? '',
      text: doc['text']?.toString() ?? '',
      createdAt: timestamp,
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