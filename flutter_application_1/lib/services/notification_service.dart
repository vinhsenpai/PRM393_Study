import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_item.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  Stream<List<AppNotificationItem>> getNotificationsStream(String userId) {
    if (userId.isEmpty) return const Stream.empty();

    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotificationItem.fromMap(
                  id: doc.id,
                  map: doc.data(),
                ))
            .toList());
  }

  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  }) async {
    if (notificationId.isEmpty || userId.isEmpty) return;

    await _notificationsCollection.doc(notificationId).update({
      'isRead': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllAsRead(String userId) async {
    if (userId.isEmpty) return;

    final unread = await _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<String> createNotification({
    required String receiverId,
    required NotificationType type,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    final userId = receiverId;
    if (userId.isEmpty) {
      throw Exception('Receiver id is empty');
    }

    final doc = await _notificationsCollection.add({
      'userId': userId,
      'type': switch (type) {
        NotificationType.order => 'order',
        NotificationType.message => 'message',
        NotificationType.system => 'system',
      },
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isRead': false,
      'payload': payload,
    });

    return doc.id;
  }
}

