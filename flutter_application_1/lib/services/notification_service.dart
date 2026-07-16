import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../models/notification_item.dart';
import '../screens/chat_screen.dart';
import '../main.dart' show navigatorKey;

// Top level background handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // The Legacy Server Key. User can paste their actual Server Key here
  static const String fcmServerKey = 'YOUR_FCM_SERVER_KEY';

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  // Initialize notifications: request permissions and setup listeners
  Future<void> initNotifications() async {
    // 1. Request notification permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
    } else {
      debugPrint('User declined or has not accepted notification permissions');
    }

    // 2. Android notification channel setup
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'messages_channel', // id
      'Message Notifications', // name
      description: 'This channel is used for chat message notifications.',
      importance: Importance.max,
      playSound: true,
    );

    // Initialize local notifications settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final Map<String, dynamic> payload =
                jsonDecode(response.payload!) as Map<String, dynamic>;
            _handleNotificationClick(payload);
          } catch (e) {
            debugPrint('Error parsing notification click payload: $e');
          }
        }
      },
    );

    // Create the channel on Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message in the foreground: ${message.messageId}');
      
      final RemoteNotification? notification = message.notification;
      final AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // 4. Listen for background clicks (when app is in background but running)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleNotificationClick(message.data);
    });

    // 5. Handle click when app is opened from terminated state
    final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state via notification click');
      _handleNotificationClick(initialMessage.data);
    }
  }

  // Handle clicking on notification to navigate to ChatScreen
  void _handleNotificationClick(Map<String, dynamic> payload) {
    debugPrint('Handling notification click with payload: $payload');
    final buyerId = payload['buyerId']?.toString();
    final buyerName = payload['buyerName']?.toString() ?? '';
    final sellerId = payload['sellerId']?.toString();
    final sellerName = payload['sellerName']?.toString() ?? '';
    final productId = payload['productId']?.toString();
    final productTitle = payload['productTitle']?.toString() ?? '';

    if ([buyerId, sellerId, productId].any((e) => e == null || e.isEmpty)) {
      debugPrint('Missing notification navigation parameters in payload');
      return;
    }

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          buyerId: buyerId!,
          buyerName: buyerName,
          sellerId: sellerId!,
          sellerName: sellerName,
          productId: productId!,
          productTitle: productTitle,
        ),
      ),
    );
  }

  // Save current device's FCM token to Firestore
  Future<void> saveFcmToken(String userId) async {
    if (userId.isEmpty) return;
    try {
      final String? token = await _fcm.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM Token successfully saved/updated for user $userId: $token');
      }
    } catch (e) {
      debugPrint('Error saving FCM Token: $e');
    }
  }

  // Delete FCM token from Firestore (e.g. on logout)
  Future<void> deleteFcmToken(String userId) async {
    if (userId.isEmpty) return;
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM Token successfully deleted for user $userId');
    } catch (e) {
      debugPrint('Error deleting FCM Token: $e');
    }
  }

  // Send Push Notification from client side via FCM legacy HTTP API
  Future<void> sendPushNotification({
    required String recipientToken,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    if (recipientToken.isEmpty) {
      debugPrint('Recipient token is empty, skipping push notification');
      return;
    }

    if (fcmServerKey == 'YOUR_FCM_SERVER_KEY' || fcmServerKey.isEmpty) {
      debugPrint('Warning: FCM Server Key is not configured yet.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$fcmServerKey',
        },
        body: jsonEncode(<String, dynamic>{
          'to': recipientToken,
          'priority': 'high',
          'notification': <String, dynamic>{
            'title': title,
            'body': body,
            'android_channel_id': 'messages_channel',
          },
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'type': 'message',
            ...payload,
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM push notification sent successfully');
      } else {
        debugPrint('FCM push notification failed with status: ${response.statusCode}, response: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending FCM push notification: $e');
    }
  }

  // Firestore stream of notifications (already existing)
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
