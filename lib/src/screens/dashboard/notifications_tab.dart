import 'package:flutter/material.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:acadia/src/core/constants/colors.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  List<Map<String, dynamic>> _notifications = [];
  String _selectedFilter = 'All';
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _hasNetworkError = false;

  // Filter options
  final List<String> _filterOptions = ['All', 'Unread', 'Payment', 'Content', 'Quiz', 'Exam', 'Achievement'];

  // Notification type colors (from blueprint)
  static const Map<String, Color> _notificationColors = {
    'payment': Color(0xFF4CAF50),     // Green
    'content': Color(0xFF2196F3),     // Blue
    'quiz': Color(0xFFFF9800),        // Orange
    'exam': Color(0xFF9C27B0),        // Purple
    'achievement': Color(0xFFFFD700), // Yellow/Gold
    'system': Color(0xFF795548),      // Brown
  };

  // Notification type icons
  static const Map<String, IconData> _notificationIcons = {
    'payment': Icons.payment,
    'content': Icons.video_library,
    'quiz': Icons.quiz,
    'exam': Icons.assignment,
    'achievement': Icons.emoji_events,
    'system': Icons.info,
  };

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (mounted) {
      setState(() {
        _hasNetworkError = false;
        _errorMessage = null;
        if (!_isLoading) _isRefreshing = true;
      });
    }

    try {
      final firebaseService = FirebaseService();
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        final data = await firebaseService.getUserNotifications();

        if (mounted) {
          setState(() {
            _notifications = List<Map<String, dynamic>>.from(data);
            _isLoading = false;
            _isRefreshing = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isRefreshing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _hasNetworkError = true;
          _errorMessage = 'Failed to load notifications. Please check your connection.';
        });
        _showErrorSnackBar(_errorMessage!);
      }
      debugPrint('Error loading notifications: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadNotifications,
        ),
      ),
    );
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final firebaseService = FirebaseService();
      await firebaseService.markNotificationRead(notificationId);

      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n['id'] == notificationId);
          if (index != -1) {
            _notifications[index]['is_read'] = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final firebaseService = FirebaseService();
      final unreadNotifications = _notifications.where((n) => n['is_read'] != true).toList();

      for (final notification in unreadNotifications) {
        await firebaseService.markNotificationRead(notification['id'].toString());
      }

      if (mounted) {
        setState(() {
          for (final notification in _notifications) {
            notification['is_read'] = true;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  int get _unreadCount => _notifications.where((n) => n['is_read'] != true).length;

  List<Map<String, dynamic>> _getFilteredNotifications() {
    if (_selectedFilter == 'All') return _notifications;
    if (_selectedFilter == 'Unread') return _notifications.where((n) => n['is_read'] != true).toList();
    return _notifications.where((n) => n['type']?.toString().toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  Color _getNotificationColor(String type) {
    return _notificationColors[type.toLowerCase()] ?? Colors.grey;
  }

  IconData _getNotificationIcon(String type) {
    return _notificationIcons[type.toLowerCase()] ?? Icons.notifications;
  }

  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) {
      try { return DateTime.parse(timestamp); } catch (e) { return null; }
    }
    try { return timestamp.toDate(); } catch (e) { return null; }
  }

  String _formatTime(dynamic createdAt) {
    final date = _parseTimestamp(createdAt);
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasNetworkError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              const Text('Connection Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_errorMessage ?? 'Unable to load notifications',
                  style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadNotifications,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final filteredNotifications = _getFilteredNotifications();

    return Column(
      children: [
        // Header with Mark All Read
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              if (_unreadCount > 0)
                TextButton(
                  onPressed: _markAllAsRead,
                  child: Text('Mark All Read (${_unreadCount})'),
                ),
            ],
          ),
        ),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: _filterOptions.map((filter) {
              final isSelected = _selectedFilter == filter;
              final count = filter == 'Unread' ? _unreadCount : null;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(filter),
                      if (count != null && count > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$count',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (v) => setState(() => _selectedFilter = filter),
                  backgroundColor: Colors.grey[200],
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Notification list
        Expanded(
          child: filteredNotifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No notifications', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text('You\'re all caught up!', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(filteredNotifications[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] == true;
    final type = notification['type']?.toString() ?? 'system';
    final color = _getNotificationColor(type);
    final icon = _getNotificationIcon(type);
    final title = notification['title']?.toString() ?? 'Notification';
    final message = notification['message']?.toString() ?? '';
    final time = _formatTime(notification['created_at']);

    return Card(
      elevation: isRead ? 0 : 2,
      color: isRead ? Colors.white : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRead ? Colors.grey[200]! : color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (!isRead) _markAsRead(notification['id'].toString());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type indicator dot + icon
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (!isRead)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (time.isNotEmpty)
                          Text(time, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                      ],
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}