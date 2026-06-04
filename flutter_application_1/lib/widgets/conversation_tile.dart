import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ConversationTile extends StatelessWidget {
  final String leadingText;
  final String subtitleText;
  final String trailingText;
  final int unreadCount;
  final VoidCallback? onTap;

  const ConversationTile({
    super.key,
    required this.leadingText,
    required this.subtitleText,
    required this.trailingText,
    required this.unreadCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 28,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            
            // Conversation details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leadingText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Time and unread badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  trailingText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}