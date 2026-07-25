import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Active, Banned
  String _subscriptionFilter = 'All'; // All, Pro, Free
  String _pathFilter = 'All'; // All academic paths

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  // Stats
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _proUsers = 0;
  int _freeUsers = 0;
  int _bannedUsers = 0;

  // Admin emails
  List<String> _adminEmails = [];

  // Status options
  final List<String> _statusOptions = ['All', 'Active', 'Banned'];

  // Subscription options
  final List<String> _subscriptionOptions = ['All', 'Pro', 'Free'];

  // Academic path options
  final List<_PathFilterOption> _pathOptions = [
    _PathFilterOption('All', 'All Paths'),
    _PathFilterOption('grade_9', 'Grade 9'),
    _PathFilterOption('grade_10', 'Grade 10'),
    _PathFilterOption('grade_11_natural', 'Grade 11 Natural Science'),
    _PathFilterOption('grade_11_social', 'Grade 11 Social Science'),
    _PathFilterOption('grade_12_natural', 'Grade 12 Natural Science'),
    _PathFilterOption('grade_12_social', 'Grade 12 Social Science'),
    _PathFilterOption('freshman_sem1_natural', 'Univ Freshman Sem 1 Natural'),
    _PathFilterOption('freshman_sem1_social', 'Univ Freshman Sem 1 Social'),
    _PathFilterOption('freshman_sem2_pre_eng', 'Univ Freshman Sem 2 Pre-Eng'),
    _PathFilterOption('freshman_sem2_other', 'Univ Freshman Sem 2 Other Nat'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final firebase = FirebaseService();

      // Load users
      final users = await firebase.getDocuments('users', orderBy: 'full_name');

      // Load admin emails
      final adminData = await firebase.getAppSettings();
      final admins = adminData?['admin_emails'];

      setState(() {
        _users = users;
        _filteredUsers = List.from(users);
        _totalUsers = users.length;
        _activeUsers = users.where((u) => u['status'] != 'banned').length;
        _bannedUsers = users.where((u) => u['status'] == 'banned').length;
        _proUsers = users.where((u) => u['is_pro'] == true).length;
        _freeUsers = users.where((u) => u['is_pro'] != true).length;

        if (admins is List) {
          _adminEmails = List<String>.from(admins);
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error loading users'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredUsers = _users.where((user) {
        // Status filter
        if (_statusFilter == 'Active' && user['status'] == 'banned')
          return false;
        if (_statusFilter == 'Banned' && user['status'] != 'banned')
          return false;

        // Subscription filter
        if (_subscriptionFilter == 'Pro' && user['is_pro'] != true)
          return false;
        if (_subscriptionFilter == 'Free' && user['is_pro'] == true)
          return false;

        // Path filter
        if (_pathFilter != 'All') {
          final userPath = _getUserPath(user);
          if (userPath != _pathFilter) return false;
        }

        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final name = user['full_name']?.toString().toLowerCase() ?? '';
          final email = user['email']?.toString().toLowerCase() ?? '';
          final phone = user['phone']?.toString().toLowerCase() ?? '';

          if (!name.contains(query) &&
              !email.contains(query) &&
              !phone.contains(query)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  String _getUserPath(Map<String, dynamic> user) {
    final level = user['school_level']?.toString() ?? '';
    final grade = user['grade']?.toString() ?? '';
    final stream = user['stream']?.toString() ?? '';
    final semester = user['semester']?.toString() ?? '';
    final track = user['track']?.toString() ?? '';

    if (level == 'high-school') {
      if (grade == '11' || grade == '12') {
        return 'grade_${grade}_$stream';
      }
      return 'grade_$grade';
    } else if (level == 'university') {
      if (semester == '2') {
        return 'freshman_sem2_$track';
      }
      return 'freshman_sem1_$stream';
    }
    return 'unknown';
  }

  // ============================================================
  // USER DETAIL VIEW (Displays user's uploaded profile photo)
  // ============================================================

  void _showUserDetails(Map<String, dynamic> user) {
    final profilePhotoUrl = user['profile_photo_url']?.toString();
    final universityName =
        user['university_name']?.toString() ?? user['university']?.toString();
    final generation = user['generation']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),

              // User Profile Photo (from user's upload)
              Center(
                child: GestureDetector(
                  onTap: profilePhotoUrl != null
                      ? () => _viewFullPhoto(profilePhotoUrl)
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                    ),
                    child: ClipOval(
                      child: profilePhotoUrl != null &&
                              profilePhotoUrl.isNotEmpty
                          ? Image.network(
                              profilePhotoUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Text(
                                      (user['full_name']?.toString() ?? 'U')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey),
                                    ),
                                  ),
                                );
                              },
                            )
                          : CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  AppColors.primary.withAlpha((255 * 0.1).toInt()),
                              child: Text(
                                (user['full_name']?.toString() ?? 'U')[0]
                                    .toUpperCase(),
                                style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user['full_name']?.toString() ?? 'Unknown',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Center(child: _buildUserStatusBadge(user)),
              const SizedBox(height: 24),

              // Personal Information
              const Text('PERSONAL INFORMATION',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey)),
              const Divider(),
              _buildInfoRow('Full Name', user['full_name']?.toString()),
              _buildInfoRow('Email', user['email']?.toString()),
              _buildInfoRow('Phone', user['phone']?.toString()),
              _buildInfoRow('Joined', _formatDate(user['created_at'])),
              _buildInfoRow('Last Active', _formatDate(user['last_active'])),
              const SizedBox(height: 16),

              // Academic Path (Complete with University)
              const Text('ACADEMIC PATH',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey)),
              const Divider(),
              _buildInfoRow(
                  'School Level',
                  user['school_level'] == 'high-school'
                      ? 'High School'
                      : 'University'),
              if (user['school_level'] == 'high-school') ...[
                _buildInfoRow('Grade', user['grade']?.toString()),
                if (user['grade'] == '11' || user['grade'] == '12')
                  _buildInfoRow(
                      'Stream',
                      user['stream'] == 'natural_science'
                          ? 'Natural Science'
                          : 'Social Science'),
              ] else if (user['school_level'] == 'university') ...[
                _buildInfoRow('Generation', generation),
                _buildInfoRow('University', universityName),
                _buildInfoRow(
                    'Year',
                    user['university_year'] == 'freshman'
                        ? 'Freshman'
                        : 'Senior'),
                if (user['university_year'] == 'freshman') ...[
                  _buildInfoRow('Semester', 'Semester ${user['semester']}'),
                  if (user['semester'] == '1')
                    _buildInfoRow(
                        'Stream',
                        user['stream'] == 'natural_science'
                            ? 'Natural Science'
                            : 'Social Science'),
                  if (user['semester'] == '2')
                    _buildInfoRow(
                        'Track',
                        user['track'] == 'pre_engineering'
                            ? 'Pre-Engineering'
                            : 'Other Natural Science'),
                ],
              ],
              _buildInfoRow('Path Status', 'Permanently Locked'),
              const SizedBox(height: 16),

              // Subscription
              const Text('SUBSCRIPTION',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey)),
              const Divider(),
              _buildInfoRow('Status', user['is_pro'] == true ? 'PRO' : 'FREE'),
              if (user['is_pro'] == true) ...[
                _buildInfoRow('Package', user['pro_package']?.toString()),
                _buildInfoRow(
                    'Amount Paid', '${user['pro_amount'] ?? '300'} ETB'),
                _buildInfoRow(
                    'Payment Method', user['pro_payment_method']?.toString()),
                _buildInfoRow(
                    'Valid From', _formatDate(user['pro_valid_from'])),
                _buildInfoRow(
                    'Valid Until', _formatDate(user['pro_valid_until'])),
                _buildInfoRow('Days Remaining',
                    _getDaysRemaining(user['pro_valid_until'])),
              ],
              const SizedBox(height: 16),

              // Study Statistics
              const Text('STUDY STATISTICS',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey)),
              const Divider(),
              _buildInfoRow('Total Study Time',
                  '${user['total_study_hours'] ?? 0} hours'),
              _buildInfoRow('Lessons Completed',
                  '${user['lessons_completed'] ?? 0} of ${user['total_lessons'] ?? 0}'),
              _buildInfoRow('Quizzes Passed',
                  '${user['quizzes_passed'] ?? 0} of ${user['total_quizzes'] ?? 0}'),
              _buildInfoRow('Average Score', '${user['average_score'] ?? 0}%'),
              _buildInfoRow(
                  'Current Streak', '${user['current_streak'] ?? 0} days'),
              _buildInfoRow('Downloads',
                  '${user['download_count'] ?? 0} items (${user['download_size'] ?? '0 GB'})'),
              const SizedBox(height: 16),

              // Payment History
              if (user['payment_history'] != null &&
                  (user['payment_history'] as List).isNotEmpty) ...[
                const Text('PAYMENT HISTORY',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey)),
                const Divider(),
                ...(user['payment_history'] as List).map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                          '${_formatDate(p['date'])} | ${p['amount']} ETB | ${p['method']} | ${p['status']?.toString().toUpperCase()}',
                          style: const TextStyle(fontSize: 13)),
                    )),
                const SizedBox(height: 16),
              ],

              // Recent Activity
              if (user['recent_activity'] != null &&
                  (user['recent_activity'] as List).isNotEmpty) ...[
                const Text('RECENT ACTIVITY',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey)),
                const Divider(),
                ...(user['recent_activity'] as List).take(5).map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${_formatDate(a['date'])} | ${a['action']}',
                          style: const TextStyle(fontSize: 13)),
                    )),
                const SizedBox(height: 16),
              ],

              // Notifications sent to user
              const Text('NOTIFICATIONS SENT',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey)),
              const Divider(),
              if (user['notifications'] != null &&
                  (user['notifications'] as List).isNotEmpty)
                ...(user['notifications'] as List).take(5).map((n) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(n['title']?.toString() ?? '',
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                          '${_formatDate(n['date'])} • ${n['read'] == true ? 'Read' : 'Unread'}',
                          style: const TextStyle(fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.edit, size: 16),
                              onPressed: () => _editUserNotification(user, n)),
                          IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 16, color: Colors.red),
                              onPressed: () =>
                                  _deleteUserNotification(user, n)),
                        ],
                      ),
                    ))
              else
                const Text('No notifications sent',
                    style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleProStatus(user);
                      },
                      icon: Icon(user['is_pro'] == true
                          ? Icons.remove_circle
                          : Icons.add_circle),
                      label: Text(
                          user['is_pro'] == true ? 'REVOKE PRO' : 'MAKE PRO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: user['is_pro'] == true
                            ? Colors.orange
                            : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleBanStatus(user);
                      },
                      icon: Icon(user['status'] == 'banned'
                          ? Icons.lock_open
                          : Icons.block),
                      label: Text(user['status'] == 'banned' ? 'UNBAN' : 'BAN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: user['status'] == 'banned'
                            ? Colors.green
                            : Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showSendNotificationDialog(user);
                      },
                      icon: const Icon(Icons.notifications),
                      label: const Text('SEND NOTIFICATION'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteUser(user);
                      },
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('DELETE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _viewFullPhoto(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black87,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image,
                          size: 64, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _toggleProStatus(Map<String, dynamic> user) async {
    final isPro = user['is_pro'] == true;
    final message = isPro
        ? 'Revoke PRO status from ${user['full_name']}?'
        : 'Make ${user['full_name']} a PRO user?';

    Map<String, dynamic>? proSelectionResult;

    if (!isPro) {
      proSelectionResult = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          String selectedPackage = 'Grade 11 Natural Science';
          return AlertDialog(
            title: const Text('Make PRO'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPackage,
                  decoration: const InputDecoration(
                      labelText: 'Select Package',
                      border: OutlineInputBorder()),
                  items: [
                    'Grade 9',
                    'Grade 10',
                    'Grade 11 Natural Science',
                    'Grade 11 Social Science',
                    'Grade 12 Natural Science',
                    'Grade 12 Social Science',
                    'Freshman Sem 1 Natural',
                    'Freshman Sem 1 Social',
                    'Freshman Sem 2 Pre-Eng',
                    'Freshman Sem 2 Other Natural',
                  ]
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => selectedPackage = v!,
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, {'package': selectedPackage}),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('CONFIRM',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
      if (proSelectionResult == null) return;
    } else {
      final confirmed = await _showConfirmDialog('Revoke PRO', message);
      if (confirmed != true) return;
    }

    setState(() => _isProcessing = true);
    try {
      final firebase = FirebaseService();
      final now = DateTime.now();

      if (isPro) {
        await firebase.updateDocument('users', user['id'], {
          'is_pro': false,
          'pro_revoked_at': now.toIso8601String(),
        });
      } else {
        await firebase.updateDocument('users', user['id'], {
          'is_pro': true,
          'pro_package': proSelectionResult?['package'],
          'pro_valid_from': now.toIso8601String(),
          'pro_valid_until':
              DateTime(now.year + 1, now.month, now.day).toIso8601String(),
        });
      }

      await _loadData();
      _applyFilters();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isPro ? 'PRO status revoked' : 'User is now PRO'),
              backgroundColor: isPro ? Colors.orange : Colors.green),
        );
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _toggleBanStatus(Map<String, dynamic> user) async {
    final isBanned = user['status'] == 'banned';
    final message =
        isBanned ? 'Unban ${user['full_name']}?' : 'Ban ${user['full_name']}?';

    String? reason;
    if (!isBanned) {
      final reasonController = TextEditingController();
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ban User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 8),
              const Text(
                  'This will log the user out and prevent future login.'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                  context, {'reason': reasonController.text.trim()}),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('BAN USER', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (result == null) return;
      reason = result['reason'];
    } else {
      final confirmed = await _showConfirmDialog('Unban User', message);
      if (confirmed != true) return;
    }

    setState(() => _isProcessing = true);
    try {
      final firebase = FirebaseService();

      await firebase.updateDocument('users', user['id'], {
        'status': isBanned ? 'active' : 'banned',
        'banned_at': isBanned ? null : DateTime.now().toIso8601String(),
        'ban_reason': isBanned ? null : reason,
        'banned_by': isBanned ? null : 'admin',
      });

      await _loadData();
      _applyFilters();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isBanned ? 'User unbanned' : 'User banned'),
              backgroundColor: isBanned ? Colors.green : Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DELETE USER'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Permanently delete ${user['full_name']}?'),
            const SizedBox(height: 8),
            const Text('This will remove:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('• Account and login credentials'),
            const Text('• All personal information'),
            const Text('• Payment history'),
            const Text('• Study progress and statistics'),
            const SizedBox(height: 8),
            const Text('This action CANNOT be undone.',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE USER',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final firebase = FirebaseService();
      await firebase.deleteDocument('users', user['id']);
      await _loadData();
      _applyFilters();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User deleted'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // ============================================================
  // NOTIFICATION MANAGEMENT
  // ============================================================

  Future<void> _showSendNotificationDialog(Map<String, dynamic> user) async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String type = 'content';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Notification to ${user['full_name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(
                    labelText: 'Type', border: OutlineInputBorder()),
                items: [
                  'payment',
                  'content',
                  'quiz',
                  'exam',
                  'achievement',
                  'system'
                ]
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.capitalize())))
                    .toList(),
                onChanged: (v) => type = v!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Message', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  messageController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('SEND'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final firebase = FirebaseService();
        await firebase.addDocument('notifications', {
          'user_id': user['id'],
          'title': titleController.text.trim(),
          'message': messageController.text.trim(),
          'type': type,
          'created_at': DateTime.now().toIso8601String(),
          'read': false,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Notification sent!'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) _showError('Error: $e');
      }
    }
  }

  Future<void> _editUserNotification(
      Map<String, dynamic> user, Map<String, dynamic> notification) async {
    final titleController = TextEditingController(text: notification['title']);
    final messageController =
        TextEditingController(text: notification['message']);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleController,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Message', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('SAVE')),
        ],
      ),
    );

    if (result == true) {
      try {
        final firebase = FirebaseService();
        await firebase.updateDocument('notifications', notification['id'], {
          'title': titleController.text.trim(),
          'message': messageController.text.trim(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Notification updated!'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) _showError('Error: $e');
      }
    }
  }

  Future<void> _deleteUserNotification(
      Map<String, dynamic> user, Map<String, dynamic> notification) async {
    final confirmed = await _showConfirmDialog(
        'Delete Notification', 'Delete this notification?');
    if (confirmed != true) return;

    try {
      final firebase = FirebaseService();
      await firebase.deleteDocument('notifications', notification['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Notification deleted!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    }
  }

  // ============================================================
  // EXPORT PDF
  // ============================================================

  Future<void> _exportUsersAsPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
                level: 0,
                child: pw.Text('ACADIA - User Export',
                    textAlign: pw.TextAlign.center)),
            pw.Header(
                level: 1,
                child: pw.Text(
                    'Generated: ${DateTime.now().toString().substring(0, 16)}')),
            pw.Header(
                level: 1,
                child: pw.Text(
                    'Filter: $_pathFilter | $_subscriptionFilter | $_statusFilter')),
            pw.Header(
                level: 1,
                child: pw.Text('Total Users: ${_filteredUsers.length}')),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    'Name',
                    'Email',
                    'Phone',
                    'Path',
                    'Status',
                    'Joined'
                  ]
                      .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))))
                      .toList(),
                ),
                ..._filteredUsers.map((user) => pw.TableRow(
                      children: [
                        user['full_name']?.toString() ?? '',
                        user['email']?.toString() ?? '',
                        user['phone']?.toString() ?? '',
                        _getUserPathDisplay(user),
                        user['is_pro'] == true ? 'PRO' : 'FREE',
                        _formatDate(user['created_at']),
                      ]
                          .map((t) => pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(t)))
                          .toList(),
                    )),
              ],
            ),
          ],
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final path =
          '${directory.path}/users_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Exported ${_filteredUsers.length} users to PDF'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) _showError('Export failed: $e');
    }
  }

  // ============================================================
  // MANAGE ADMINS
  // ============================================================

  Future<void> _showManageAdminsDialog() async {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Manage Admin Emails'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._adminEmails.map((email) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.email),
                    title: Text(email),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () async {
                        await _removeAdmin(email);
                        setDialogState(() => _adminEmails.remove(email));
                      },
                    ),
                  )),
              const Divider(),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Add Admin Email',
                  hintText: 'admin@example.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isNotEmpty) {
                    await _addAdmin(email);
                    setDialogState(() => _adminEmails.add(email));
                    emailController.clear();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Admin'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  Future<void> _addAdmin(String email) async {
    try {
      final firebase = FirebaseService();
      final currentSettings = await firebase.getAppSettings();
      final admins = List<String>.from(currentSettings?['admin_emails'] ?? []);
      if (!admins.contains(email)) {
        admins.add(email);
        await firebase.updateAppSettings({'admin_emails': admins});
      }
    } catch (e) {
      debugPrint('Error adding admin: $e');
    }
  }

  Future<void> _removeAdmin(String email) async {
    try {
      final firebase = FirebaseService();
      final currentSettings = await firebase.getAppSettings();
      final admins = List<String>.from(currentSettings?['admin_emails'] ?? []);
      admins.remove(email);
      await firebase.updateAppSettings({'admin_emails': admins});
    } catch (e) {
      debugPrint('Error removing admin: $e');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _buildUserStatusBadge(Map<String, dynamic> user) {
    final isPro = user['is_pro'] == true;
    final isBanned = user['status'] == 'banned';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isPro
                ? Colors.green.withAlpha((255 * 0.1).toInt())
                : Colors.grey.withAlpha((255 * 0.1).toInt()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isPro ? Colors.green : Colors.grey),
          ),
          child: Text(isPro ? 'PRO ●' : 'FREE ○',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPro ? Colors.green : Colors.grey)),
        ),
        if (isBanned) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red),
            ),
            child: const Text('BANNED 🔴',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 130,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
              child: Text(value ?? 'N/A',
                  style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }

  String _getUserPathDisplay(Map<String, dynamic> user) {
    final level = user['school_level']?.toString() ?? '';
    if (level == 'high-school') {
      final grade = user['grade']?.toString() ?? '';
      final stream = user['stream']?.toString() ?? '';
      if (grade == '11' || grade == '12') {
        return 'Grade $grade ${stream == 'natural_science' ? 'Natural Science' : 'Social Science'}';
      }
      return 'Grade $grade';
    } else if (level == 'university') {
      final year = user['university_year']?.toString() ?? '';
      final semester = user['semester']?.toString() ?? '';
      final stream = user['stream']?.toString() ?? '';
      final track = user['track']?.toString() ?? '';
      final university = user['university_name']?.toString() ??
          user['university']?.toString() ??
          '';
      final generation = user['generation']?.toString() ?? '';

      if (year == 'freshman') {
        if (semester == '2') {
          return 'Freshman Sem 2 ${track == 'pre_engineering' ? 'Pre-Engineering' : 'Other Natural Science'}\n$university ($generation)';
        }
        return 'Freshman Sem 1 ${stream == 'natural_science' ? 'Natural Science' : 'Social Science'}\n$university ($generation)';
      }
      return 'Senior\n$university ($generation)';
    }
    return 'Unknown';
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      DateTime d = date is DateTime ? date : DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (e) {
      return date.toString();
    }
  }

  String _getDaysRemaining(dynamic validUntil) {
    if (validUntil == null) return 'N/A';
    try {
      DateTime d = validUntil is DateTime
          ? validUntil
          : DateTime.parse(validUntil.toString());
      final remaining = d.difference(DateTime.now()).inDays;
      return remaining > 0 ? '$remaining days' : 'Expired';
    } catch (e) {
      return 'N/A';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        leading: IconButton(
            onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(
              onPressed: _showManageAdminsDialog,
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Manage Admins'),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard('Total', _totalUsers, AppColors.primary),
                const SizedBox(width: 8),
                _buildStatCard('Active', _activeUsers, Colors.green),
                const SizedBox(width: 8),
                _buildStatCard('Pro', _proUsers, Colors.purple),
                const SizedBox(width: 8),
                _buildStatCard('Free', _freeUsers, Colors.grey),
                const SizedBox(width: 8),
                _buildStatCard('Banned', _bannedUsers, Colors.red),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone number...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          _applyFilters();
                        })
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) {
                _searchQuery = v;
                _applyFilters();
              },
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown(
                      'Path',
                      _pathFilter,
                      _pathOptions
                          .map((p) => DropdownMenuItem(
                              value: p.value,
                              child: Text(p.label,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(), (v) {
                    _pathFilter = v!;
                    _applyFilters();
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterDropdown(
                      'Status',
                      _statusFilter,
                      _statusOptions
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(), (v) {
                    _statusFilter = v!;
                    _applyFilters();
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterDropdown(
                      'Sub',
                      _subscriptionFilter,
                      _subscriptionOptions
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(), (v) {
                    _subscriptionFilter = v!;
                    _applyFilters();
                  }),
                ),
              ],
            ),
          ),

          // Export buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${_filteredUsers.length} users',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _exportUsersAsPDF,
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label:
                      const Text('Export PDF', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          // User list - Shows profile photos uploaded by users
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Text('No users found',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isPro = user['is_pro'] == true;
                          final isBanned = user['status'] == 'banned';
                          final profilePhotoUrl =
                              user['profile_photo_url']?.toString();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () => _showUserDetails(user),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // User's profile photo (uploaded by user in their settings)
                                    ClipOval(
                                      child: profilePhotoUrl != null &&
                                              profilePhotoUrl.isNotEmpty
                                          ? Image.network(
                                              profilePhotoUrl,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child: SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: AppColors.primary
                                                      .withAlpha((255 * 0.1).toInt()),
                                                  child: Center(
                                                    child: Text(
                                                      (user['full_name']
                                                                  ?.toString() ??
                                                              'U')[0]
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              AppColors.primary,
                                                          fontSize: 18),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withAlpha((255 * 0.1).toInt()),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  (user['full_name']
                                                              ?.toString() ??
                                                          'U')[0]
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.primary,
                                                      fontSize: 18),
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              user['full_name']?.toString() ??
                                                  'Unknown',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15)),
                                          Text(user['email']?.toString() ?? '',
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13)),
                                          Text(user['phone']?.toString() ?? '',
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12)),
                                          Text(_getUserPathDisplay(user),
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.primary)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isPro
                                                ? Colors.green.withAlpha((255 * 0.1).toInt())
                                                : Colors.grey.withAlpha((255 * 0.1).toInt()),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(isPro ? 'PRO' : 'FREE',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isPro
                                                      ? Colors.green
                                                      : Colors.grey)),
                                        ),
                                        if (isBanned) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.red.withAlpha((255 * 0.1).toInt()),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Text('BANNED',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha((255 * 0.1).toInt()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(count.toString(),
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value,
      List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      isExpanded: true,
      style: const TextStyle(fontSize: 13),
      items: items,
      onChanged: onChanged,
    );
  }
}

// ============================================================
// HELPER CLASSES
// ============================================================

class _PathFilterOption {
  final String value;
  final String label;
  _PathFilterOption(this.value, this.label);
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
