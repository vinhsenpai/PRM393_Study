import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'order_detail_section.dart';

class OrderTimeline extends StatelessWidget {
  final String status;

  const OrderTimeline({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return OrderDetailSection(
      title: 'Order Timeline',
      children: [
        _buildTimelineStep(
          'Pending',
          Icons.pending_actions,
          status == 'pending' || status == 'processing' || status == 'completed',
          status == 'pending'
              ? true
              : status == 'processing' || status == 'completed'
                  ? false // Pending is always completed first
                  : false,
        ),
        _buildTimelineStep(
          'Processing',
          Icons.timer,
          status == 'processing' || status == 'completed',
          status == 'processing'
              ? true
              : status == 'completed'
                  ? false
                  : false,
        ),
        _buildTimelineStep(
          'Completed',
          Icons.check_circle,
          status == 'completed',
          status == 'completed'
              ? true
              : false,
        ),
      ],
    );
  }

  Widget _buildTimelineStep(
    String label,
    IconData icon,
    bool isActive,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          // Circle
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? Colors.green
                  : isActive
                      ? AppTheme.primaryColor
                      : AppTheme.surfaceColor,
              border: isCompleted || isActive
                  ? null
                  : Border.all(color: AppTheme.borderColor),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isCompleted
                  ? Colors.white
                  : isActive
                      ? Colors.white
                      : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          // Line
          Expanded(
            child: Container(
              height: 2,
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.5)
                  : AppTheme.borderColor,
            ),
          ),
          const SizedBox(width: 12),
          // Label
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                color: isCompleted
                    ? Colors.greenAccent
                    : isActive
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}