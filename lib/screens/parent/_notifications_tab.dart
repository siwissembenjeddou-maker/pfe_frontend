import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../services/api_service.dart';
import '../../../widgets/common_widgets.dart';

class NotificationsTab extends StatefulWidget {
  final List<dynamic> Function() getNotifications;
  final VoidCallback onRefresh;
  const NotificationsTab(
      {super.key, required this.getNotifications, required this.onRefresh});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  @override
  Widget build(BuildContext context) {
    final notifications = widget.getNotifications();
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_off_outlined,
              message:
                  'No notifications yet.\nComplete assessments to receive alerts.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationCard(
                  notification: notification,
                  onRefresh: widget.onRefresh,
                );
              },
            ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final dynamic notification;
  final VoidCallback onRefresh;
  const _NotificationCard(
      {required this.notification, required this.onRefresh});

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  String get _type => widget.notification['type'] ?? '';

  Future<void> _markReadIfNeeded() async {
    final isUnread = widget.notification['is_read'] != true;
    if (!isUnread) return;

    final id = widget.notification['id'];
    if (id == null) return;

    try {
      await ApiService.markNotificationRead(id);
      widget.onRefresh();
    } catch (_) {
      // Ignore silently to avoid breaking UX
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.notification['title'] ?? 'Notification';
    final message = widget.notification['message'] ?? '';
    final isUnread = widget.notification['is_read'] != true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: _getColor(_type).withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await _markReadIfNeeded();
          _showNotificationDetail(context, title, message, _type);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _getColor(_type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIcon(_type),
                      color: _getColor(_type),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimestamp(widget.notification['created_at']),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUnread)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getColor(_type),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),

              // Report header for psychologist reports
              if (_type == 'psychologist_report' && message.contains('➤')) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getColor(_type).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getColor(_type).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    message.split('\n\n').first,
                    style: TextStyle(
                      color: _getColor(_type),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message.split('\n\n').length > 1
                      ? message.split('\n\n').skip(1).join('\n\n')
                      : '',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetail(
      BuildContext context, String title, String message, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Icon + title
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getColor(type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:
                        Icon(_getIcon(type), color: _getColor(type), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                _formatTimestamp(widget.notification['created_at']),
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
              const Divider(height: 32),
              const Text(
                'Details',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),

              if (type == 'psychologist_report' && message.contains('➤')) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _getColor(type).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _getColor(type).withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    message.split('\n\n').first,
                    style: TextStyle(
                      color: _getColor(type),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  message.split('\n\n').length > 1
                      ? message.split('\n\n').skip(1).join('\n\n')
                      : message,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ] else ...[
                Text(
                  message.isNotEmpty ? message : 'No additional details.',
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return timestamp.toString();
    }
  }

  IconData _getIcon(String type) {
    return switch (type) {
      'child_added' => Icons.person_add_alt_1,
      'assessment_result' => Icons.assessment,
      'review_complete' => Icons.check_circle_outline,
      'psychologist_report' => Icons.description,
      'message' => Icons.message,
      'reminder' => Icons.schedule,
      _ => Icons.notification_important,
    };
  }

  Color _getColor(String type) {
    return switch (type) {
      'child_added' => Colors.purple,
      'assessment_result' => Colors.blue,
      'review_complete' => const Color(0xFF27AE60),
      'psychologist_report' => const Color(0xFF8E44AD),
      'message' => Colors.green,
      'reminder' => Colors.orange,
      _ => Colors.grey,
    };
  }
}
