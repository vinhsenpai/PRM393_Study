import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { order, message, system }

class AppNotificationItem {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  /// Payload used for navigation
  final Map<String, dynamic> payload;

  AppNotificationItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
    required this.payload,
  });

  factory AppNotificationItem.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final typeStr = (map['type'] ?? 'system').toString();

    final type = switch (typeStr) {
      'order' => NotificationType.order,
      'message' => NotificationType.message,
      _ => NotificationType.system,
    };

    final ts = map['createdAt'];
    final timestamp = ts is Timestamp
        ? ts.toDate()
        : (ts is DateTime ? ts : DateTime.now());

    return AppNotificationItem(
      id: id,
      userId: map['userId']?.toString() ?? '',
      type: type,
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      timestamp: timestamp,
      isRead: (map['isRead'] ?? false) == true,
      payload: (map['payload'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(map['payload'] as Map<String, dynamic>)
          : <String, dynamic>{},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': switch (type) {
        NotificationType.order => 'order',
        NotificationType.message => 'message',
        NotificationType.system => 'system',
      },
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'payload': payload,
    };
  }
}

