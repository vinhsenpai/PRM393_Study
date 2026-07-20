import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_item.dart';
import '../screens/chat_screen.dart';
import '../main.dart' show navigatorKey;

// Top level background handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling background message: ${message.messageId}");

  // Initialize local notifications to show notification even in background/terminated
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await localNotifications.initialize(initializationSettings);

  // Create Android notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'messages_channel',
    'Message Notifications',
    description: 'This channel is used for chat message notifications.',
    importance: Importance.max,
    playSound: true,
    showBadge: true,
    enableVibration: true,
  );

  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Show local notification (get title/body from data)
  final title = message.data['title']?.toString() ?? 'New Message';
  final body = message.data['body']?.toString() ?? '';

  if (title.isNotEmpty || body.isNotEmpty) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'messages_channel',
          'Message Notifications',
          channelDescription:
              'This channel is used for chat message notifications.',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          showWhen: true,
          autoCancel: true,
          enableVibration: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final chatId = message.data['chatId']?.toString();
    final notificationId = chatId != null ? chatId.hashCode : title.hashCode;

    await localNotifications.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  String? _currentUserId;
  StreamSubscription? _notificationsSubscription;

  // Initialize notifications: request permissions and setup listeners
  Future<void> initNotifications() async {
    if (kIsWeb) {
      debugPrint('NotificationService initialization bypassed on Web.');
      return;
    }
    // 1. Request notification permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
    } else {
      debugPrint(
        'User declined or has not accepted notification permissions (status: ${settings.authorizationStatus})',
      );
    }

    // 2. Android notification channel setup for heads-up notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'messages_channel', // id
      'Message Notifications', // name
      description: 'This channel is used for chat message notifications.',
      importance: Importance.max,
      playSound: true,
      showBadge: true,
      enableVibration: true,
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
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 3. Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM Token refreshed: $newToken');
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        await saveFcmToken(_currentUserId!);
      }
    });

    // 4. Listen for foreground messages from FCM
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        'Got a message in the foreground: ${message.messageId}, data: ${message.data}',
      );

      // Get title/body from data (since we send only data messages now)
      final title = message.data['title']?.toString() ?? 'New Message';
      final body = message.data['body']?.toString() ?? '';

      if (title.isNotEmpty || body.isNotEmpty) {
        // Use chatId from payload as notification ID to group same chat notifications
        final chatId = message.data['chatId']?.toString();
        final notificationId = chatId != null
            ? chatId.hashCode
            : title.hashCode;

        _showLocalNotification(
          id: notificationId,
          title: title,
          body: body,
          payload: message.data,
        );
      }
    });

    // 5. Listen for background clicks (when app is in background but running)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleNotificationClick(message.data);
    });

    // 6. Handle click when app is opened from terminated state
    final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state via notification click');
      _handleNotificationClick(initialMessage.data);
    }
  }

  // Show local notification with heads-up
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'messages_channel',
          'Message Notifications',
          channelDescription:
              'This channel is used for chat message notifications.',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          showWhen: true,
          autoCancel: true,
          enableVibration: true,
          fullScreenIntent:
              false, // Set to true if you want full-screen for urgent
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: jsonEncode(payload),
    );
  }

  // Listen for new notifications from Firestore (for UI updates only, no notifications)
  void listenForNewNotifications(String userId) {
    if (kIsWeb || userId.isEmpty) return;
    _currentUserId = userId;

    // Cancel previous subscription if any
    _notificationsSubscription?.cancel();

    // Just listen to keep the stream active for UI (e.g., NotificationsScreen)
    // No need to show local notifications here - FCM handles that via Cloud Functions
    _notificationsSubscription = _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          // Do nothing - just keep the stream open for UI listeners
        });
  }

  // Stop listening for notifications
  void stopListeningForNotifications() {
    _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
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
    if (kIsWeb || userId.isEmpty) return;
    _currentUserId = userId;
    try {
      final String? token = await _fcm.getToken();
      if (token != null && token.isNotEmpty) {
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM Token successfully saved for user $userId: $token');
      } else {
        debugPrint('FCM Token returned null or empty string for user $userId');
      }
    } catch (e) {
      debugPrint('Error saving FCM Token for user $userId: $e');
    }
  }

  // Delete FCM token from Firestore (e.g. on logout)
  Future<void> deleteFcmToken(String userId) async {
    if (kIsWeb || userId.isEmpty) return;
    try {
      stopListeningForNotifications();
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM Token successfully deleted for user $userId');
    } catch (e) {
      debugPrint('Error deleting FCM Token: $e');
    }
  }

  // Firestore stream of notifications (already existing)
  Stream<List<AppNotificationItem>> getNotificationsStream(String userId) {
    if (userId.isEmpty) return const Stream.empty();

    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    AppNotificationItem.fromMap(id: doc.id, map: doc.data()),
              )
              .toList(),
        );
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
