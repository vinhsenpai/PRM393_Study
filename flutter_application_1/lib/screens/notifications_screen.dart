import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/notification_item.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import 'order_detail_screen.dart';
import 'chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: userId.isEmpty
                ? null
                : () async {
                    await _notificationService.markAllAsRead(userId);
                  },
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: userId.isEmpty
          ? _buildEmptyState()
          : StreamBuilder<List<AppNotificationItem>>(
              stream: _notificationService.getNotificationsStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final notifications = snapshot.data ?? [];
                if (notifications.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationTile(
                      context,
                      notifications[index],
                      index,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    AppNotificationItem item,
    int index,
  ) {
    final icon = _getIconForType(item.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : Colors.blue.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              item.isRead ? Colors.grey[200]! : Colors.blue.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: icon.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon.data, color: icon.color, size: 24),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
            fontSize: 16,
            color: const Color(0xFF0F172A),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.body,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(item.timestamp),
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
        onTap: () async {
          final auth = context.read<AuthProvider>();
          final userId = auth.currentUser?.id ?? '';

          await _notificationService.markAsRead(
            notificationId: item.id,
            userId: userId,
          );

          if (!context.mounted) return;
          await _navigateFromNotification(context, item);
        },
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
  }

  Future<void> _navigateFromNotification(
    BuildContext context,
    AppNotificationItem item,
  ) async {
    if (item.type == NotificationType.order) {
      final orderId = item.payload['orderId']?.toString();
      if (orderId == null || orderId.isEmpty) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: orderId),
        ),
      );
      return;
    }

    if (item.type == NotificationType.message) {
      // payload expected: buyerId,buyerName,sellerId,sellerName,productId,productTitle
      final buyerId = item.payload['buyerId']?.toString();
      final buyerName = item.payload['buyerName']?.toString() ?? '';
      final sellerId = item.payload['sellerId']?.toString();
      final sellerName = item.payload['sellerName']?.toString() ?? '';
      final productId = item.payload['productId']?.toString();
      final productTitle = item.payload['productTitle']?.toString() ?? '';

      if ([buyerId, sellerId, productId].any((e) => e == null || e.isEmpty)) {
        return;
      }

      await Navigator.of(context).push(
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
      return;
    }

    // system: do nothing for now
  }

  ({IconData data, Color color}) _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return (data: Icons.shopping_bag_rounded, color: Colors.green);
      case NotificationType.message:
        return (data: Icons.chat_bubble_outline_rounded, color: Colors.blue);
      case NotificationType.system:
        return (data: Icons.info_rounded, color: Colors.orange);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

