import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum NotificationType { order, system, support, verification }

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notifications for demonstration
    final List<NotificationItem> notifications = [
      NotificationItem(
        id: '1',
        title: 'Order Successful',
        body: 'Your purchase of PUBG Mobile Account has been confirmed.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        type: NotificationType.order,
      ),
      NotificationItem(
        id: '2',
        title: 'New Support Message',
        body: 'Admin has replied to your inquiry about payment.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.support,
        isRead: true,
      ),
      NotificationItem(
        id: '3',
        title: 'Account Verified',
        body: 'Congratulations! Your listing "Genshin Impact AR 55" is now live.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.verification,
      ),
      NotificationItem(
        id: '4',
        title: 'System Update',
        body: 'We have updated our terms of service. Please review them.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: NotificationType.system,
        isRead: true,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark all as read', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationTile(context, notifications[index], index);
              },
            ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, NotificationItem item, int index) {
    IconData iconData;
    Color iconColor;

    switch (item.type) {
      case NotificationType.order:
        iconData = Icons.shopping_bag_rounded;
        iconColor = Colors.green;
        break;
      case NotificationType.system:
        iconData = Icons.info_rounded;
        iconColor = Colors.blue;
        break;
      case NotificationType.support:
        iconData = Icons.support_agent_rounded;
        iconColor = Colors.orange;
        break;
      case NotificationType.verification:
        iconData = Icons.verified_user_rounded;
        iconColor = Colors.purple;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : Colors.blue.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isRead ? Colors.grey[200]! : Colors.blue.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 24),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
            fontSize: 16,
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
        onTap: () {
          // Navigate to related screen based on type
        },
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(color: Colors.grey[600], fontSize: 18),
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
