import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';

class NotificationCreationScreen extends StatefulWidget {
  const NotificationCreationScreen({super.key});

  @override
  State<NotificationCreationScreen> createState() =>
      _NotificationCreationScreenState();
}

class _NotificationCreationScreenState
    extends State<NotificationCreationScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Notification type
  String _notificationType = 'content'; // payment, content, quiz, exam, achievement, system

  // Target audience
  String _targetAudience = 'all'; // all, specific_path, specific_users
  List<String> _selectedPaths = [];
  List<String> _selectedUserIds = [];
  List<Map<String, dynamic>> _searchedUsers = [];

  // Image
  String? _imageUrl;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;
  String? _uploadErrorMessage;

  // Search state
  String _searchQuery = '';
  bool _isSearchingUsers = false;

  // List state
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _filteredNotifications = [];
  bool _isLoading = false;
  bool _isSending = false;
  String _statusFilter = 'All';

  // FreeImage.host API Key
  static const String _freeImageApiKey = '6d207e02198a847aa98d0a2a901485a5';

  // Notification types
  final Map<String, _NotificationTypeInfo> _notificationTypes = {
    'payment': _NotificationTypeInfo('Payment', Icons.payment, const Color(0xFF4CAF50)),
    'content': _NotificationTypeInfo('Content', Icons.description, const Color(0xFF2196F3)),
    'quiz': _NotificationTypeInfo('Quiz', Icons.quiz, const Color(0xFFFF9800)),
    'exam': _NotificationTypeInfo('Exam', Icons.assignment, const Color(0xFF9C27B0)),
    'achievement': _NotificationTypeInfo('Achievement', Icons.emoji_events, const Color(0xFFFFD700)),
    'system': _NotificationTypeInfo('System', Icons.settings, const Color(0xFF795548)),
  };

  // Available academic paths for targeting
  final List<_PathOption> _availablePaths = [
    _PathOption('grade_9', 'Grade 9'),
    _PathOption('grade_10', 'Grade 10'),
    _PathOption('grade_11_natural', 'Grade 11 Natural Science'),
    _PathOption('grade_11_social', 'Grade 11 Social Science'),
    _PathOption('grade_12_natural', 'Grade 12 Natural Science'),
    _PathOption('grade_12_social', 'Grade 12 Social Science'),
    _PathOption('freshman_sem1_natural', 'Univ Freshman Sem 1 Natural'),
    _PathOption('freshman_sem1_social', 'Univ Freshman Sem 1 Social'),
    _PathOption('freshman_sem2_pre_eng', 'Univ Freshman Sem 2 Pre-Eng'),
    _PathOption('freshman_sem2_other', 'Univ Freshman Sem 2 Other Natural'),
  ];

  final List<String> _statusOptions = ['All', 'sent', 'scheduled', 'draft'];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final firebase = FirebaseService();
      final notifications = await firebase.getDocuments('notifications',
          orderBy: 'created_at', descending: true);

      setState(() {
        _notifications = notifications;
        _filteredNotifications = List.from(notifications);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading notifications'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredNotifications = _notifications.where((n) {
        if (_statusFilter != 'All' && n['status']?.toString() != _statusFilter) {
          return false;
        }
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final title = n['title']?.toString().toLowerCase() ?? '';
          final message = n['message']?.toString().toLowerCase() ?? '';
          if (!title.contains(query) && !message.contains(query)) return false;
        }
        return true;
      }).toList();
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.length < 2) {
      setState(() => _searchedUsers = []);
      return;
    }

    setState(() => _isSearchingUsers = true);
    try {
      final firebase = FirebaseService();
      final allUsers = await firebase.getDocuments('users');
      final results = allUsers.where((user) {
        final name = user['full_name']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';
        final phone = user['phone']?.toString().toLowerCase() ?? '';
        final q = query.toLowerCase();
        return name.contains(q) || email.contains(q) || phone.contains(q);
      }).toList();

      setState(() => _searchedUsers = results);
    } catch (e) {
      debugPrint('Error searching users: $e');
    } finally {
      setState(() => _isSearchingUsers = false);
    }
  }

  // ============================================================
  // IMAGE UPLOAD TO FREEIMAGE.HOST
  // ============================================================

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    
    if (result == null) return;

    setState(() {
      _isUploadingImage = true;
      _uploadProgress = 0.0;
      _uploadErrorMessage = null;
    });

    try {
      // Upload to FreeImage.host
      final imageUrl = await _uploadToFreeImage(result.path);
      
      if (imageUrl != null) {
        setState(() {
          _imageUrl = imageUrl;
          _imageUrlController.text = imageUrl;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded to FreeImage.host successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to upload to FreeImage.host');
      }
    } catch (e) {
      setState(() {
        _uploadErrorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<String?> _uploadToFreeImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      
      // FreeImage.host API endpoint
      const uploadUrl = 'https://freeimage.host/api/1/upload';
      
      final dio = Dio();
      
      // Create multipart request
      final formData = FormData.fromMap({
        'key': _freeImageApiKey,
        'action': 'upload',
        'source': MultipartFile.fromBytes(
          bytes,
          filename: 'notification_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'format': 'json',
      });
      
      // Update progress
      final response = await dio.post(
        uploadUrl,
        data: formData,
        onSendProgress: (sent, total) {
          if (mounted) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
        },
      );
      
      if (response.statusCode == 200 && response.data['status_code'] == 200) {
        // Get the direct image URL from response
        final imageUrl = response.data['image']['url'];
        return imageUrl;
      } else {
        debugPrint('FreeImage.host upload failed: ${response.data}');
        final errorMsg = response.data['status_txt'] ?? 'Upload failed';
        throw Exception(errorMsg);
      }
    } on DioException catch (e) {
      debugPrint('FreeImage.host Dio error: $e');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('FreeImage.host upload error: $e');
      rethrow;
    }
  }

  Future<void> _pickImageFromUrl() async {
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Image URL'),
        content: TextField(
          controller: _imageUrlController,
          decoration: const InputDecoration(
            labelText: 'Image URL',
            hintText: 'https://i.ibb.co/... or any image URL',
            border: OutlineInputBorder(),
            helperText: 'Supports any direct image link from FreeImage.host, Imgur, etc.',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = _imageUrlController.text.trim();
              if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))) {
                Navigator.pop(context, url);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid URL'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (url != null) {
      setState(() {
        _imageUrl = url;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
      _imageUrlController.clear();
      _uploadErrorMessage = null;
    });
  }

  // ============================================================
  // SEND NOTIFICATION
  // ============================================================

  Future<void> _broadcastNotification() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a notification title');
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      _showError('Please enter a notification message');
      return;
    }

    // Get target user count
    List<String> targetIds = [];
    if (_targetAudience == 'specific_users') {
      targetIds = List.from(_selectedUserIds);
      if (targetIds.isEmpty) {
        _showError('Please select at least one user');
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Broadcast Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${_notificationTypes[_notificationType]?.label ?? _notificationType}'),
            const SizedBox(height: 8),
            Text('Title: ${_titleController.text.trim()}'),
            const SizedBox(height: 8),
            Text('Message: ${_messageController.text.trim()}'),
            if (_imageUrl != null) ...[
              const SizedBox(height: 8),
              Text('Image: Attached', style: TextStyle(color: Colors.green)),
            ],
            const SizedBox(height: 16),
            Text(
              _targetAudience == 'all'
                  ? 'Target: All Users'
                  : _targetAudience == 'specific_path'
                      ? 'Target: ${_selectedPaths.length} academic paths'
                      : 'Target: ${_selectedUserIds.length} specific users',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Send Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSending = true);
    try {
      final firebase = FirebaseService();

      final notificationData = {
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'type': _notificationType,
        'target_audience': _targetAudience,
        'target_paths': _targetAudience == 'specific_path' ? _selectedPaths : [],
        'target_user_ids': _targetAudience == 'specific_users' ? _selectedUserIds : [],
        'image_url': _imageUrl, // Add image URL from FreeImage.host
        'created_at': DateTime.now().toIso8601String(),
        'created_by': FirebaseAuth.instance.currentUser?.email ?? 'admin',
        'status': 'sent',
        'sent_at': DateTime.now().toIso8601String(),
      };

      await firebase.addDocument('notifications', notificationData);
      await _loadNotifications();
      _clearForm();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification broadcast successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending notification: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  // ============================================================
  // EDIT / DELETE NOTIFICATION
  // ============================================================

  Future<void> _editNotification(Map<String, dynamic> notification) async {
    _titleController.text = notification['title']?.toString() ?? '';
    _messageController.text = notification['message']?.toString() ?? '';
    _notificationType = notification['type']?.toString() ?? 'content';
    _targetAudience = notification['target_audience']?.toString() ?? 'all';
    _selectedPaths = List<String>.from(notification['target_paths'] ?? []);
    _selectedUserIds = List<String>.from(notification['target_user_ids'] ?? []);
    _imageUrl = notification['image_url']?.toString();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Notification'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type selector
              _buildTypeSelector(),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              // Image preview
              if (_imageUrl != null) _buildImagePreview(),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final firebase = FirebaseService();
        await firebase.updateDocument('notifications', notification['id'], {
          'title': _titleController.text.trim(),
          'message': _messageController.text.trim(),
          'type': _notificationType,
          'image_url': _imageUrl,
          'updated_at': DateTime.now().toIso8601String(),
          'updated_by': FirebaseAuth.instance.currentUser?.email ?? 'admin',
        });
        await _loadNotifications();
        _clearForm();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification updated!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteNotification(Map<String, dynamic> notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: Text('Delete "${notification['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final firebase = FirebaseService();
        await firebase.deleteDocument('notifications', notification['id']);
        await _loadNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification deleted!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _clearForm() {
    _titleController.clear();
    _messageController.clear();
    _imageUrlController.clear();
    setState(() {
      _notificationType = 'content';
      _targetAudience = 'all';
      _selectedPaths = [];
      _selectedUserIds = [];
      _imageUrl = null;
      _uploadErrorMessage = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  // ============================================================
  // BUILD UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Create Notification'),
              Tab(text: 'Notification History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ============================================
            // TAB 1: CREATE NOTIFICATION
            // ============================================
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification Type
                  Text('Notification Type', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTypeSelector(),
                  const SizedBox(height: 24),

                  // Target Audience
                  Text('Target Audience', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTargetAudienceSelector(),
                  const SizedBox(height: 24),

                  // Path selector (if specific paths)
                  if (_targetAudience == 'specific_path') ...[
                    Text('Select Academic Paths', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availablePaths.map((path) {
                        final isSelected = _selectedPaths.contains(path.value);
                        return FilterChip(
                          label: Text(path.label, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                _selectedPaths.add(path.value);
                              } else {
                                _selectedPaths.remove(path.value);
                              }
                            });
                          },
                          selectedColor: AppColors.primary.withOpacity(0.2),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(onPressed: () => setState(() => _selectedPaths = _availablePaths.map((p) => p.value).toList()), child: const Text('Select All')),
                        TextButton(onPressed: () => setState(() => _selectedPaths = []), child: const Text('Clear All')),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // User selector (if specific users)
                  if (_targetAudience == 'specific_users') ...[
                    Text('Search and Select Users', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name, email, or phone...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearchingUsers ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        ) : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) {
                        _searchQuery = v;
                        _searchUsers(v);
                      },
                    ),
                    const SizedBox(height: 8),
                    if (_searchedUsers.isNotEmpty) ...[
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _searchedUsers[index];
                            final userId = user['id']?.toString() ?? '';
                            final isSelected = _selectedUserIds.contains(userId);
                            return CheckboxListTile(
                              dense: true,
                              value: isSelected,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedUserIds.add(userId);
                                  } else {
                                    _selectedUserIds.remove(userId);
                                  }
                                });
                              },
                              title: Text(user['full_name']?.toString() ?? 'Unknown', style: const TextStyle(fontSize: 14)),
                              subtitle: Text(
                                '${user['email']?.toString() ?? ''} • ${user['phone']?.toString() ?? ''}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (_selectedUserIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('${_selectedUserIds.length} users selected',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Notification Details
                  Text('Notification Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g., New Content Available',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      hintText: 'Enter the notification message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Image Upload Section
                  Text('Notification Image (Optional)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildImageUploadSection(),
                  const SizedBox(height: 32),

                  // Broadcast button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _broadcastNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSending
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('BROADCAST NOTIFICATION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // ============================================
            // TAB 2: NOTIFICATION HISTORY
            // ============================================
            Column(
              children: [
                // Search and filter
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search notifications...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (v) {
                            _searchQuery = v;
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _statusFilter,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s == 'All' ? 'All' : s.capitalize()))).toList(),
                          onChanged: (v) {
                            setState(() => _statusFilter = v ?? 'All');
                            _applyFilters();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredNotifications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text('No notifications found', style: TextStyle(color: Colors.grey[600])),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredNotifications.length,
                              itemBuilder: (context, index) {
                                final n = _filteredNotifications[index];
                                return _buildNotificationCard(n);
                              },
                            ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image preview if exists
        if (_imageUrl != null) ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        alignment: Alignment.center,
                        color: Colors.grey[100],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('Failed to load image', style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 16),
                      onPressed: _removeImage,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 16,
                    ),
                    radius: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Upload buttons
        if (_isUploadingImage) ...[
          LinearProgressIndicator(value: _uploadProgress),
          const SizedBox(height: 8),
          Text('Uploading to FreeImage.host: ${(_uploadProgress * 100).toInt()}%',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickAndUploadImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Upload from Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImageFromUrl,
                  icon: const Icon(Icons.link),
                  label: const Text('Paste Image URL'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Images are uploaded to FreeImage.host. Supports JPG, PNG, GIF up to 10MB.',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          if (_uploadErrorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Error: $_uploadErrorMessage',
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _imageUrl!,
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 120,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 120,
              alignment: Alignment.center,
              color: Colors.grey[100],
              child: Text('Failed to load image', style: TextStyle(color: Colors.grey[500])),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _notificationTypes.entries.map((entry) {
        final type = entry.key;
        final info = entry.value;
        final isSelected = _notificationType == type;
        return ChoiceChip(
          avatar: Icon(info.icon, size: 18, color: isSelected ? Colors.white : info.color),
          label: Text(info.label),
          selected: isSelected,
          onSelected: (v) => setState(() => _notificationType = type),
          selectedColor: info.color,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTargetAudienceSelector() {
    return Column(
      children: [
        RadioListTile<String>(
          value: 'all',
          groupValue: _targetAudience,
          onChanged: (v) => setState(() => _targetAudience = v!),
          title: const Text('All Users'),
          subtitle: const Text('Send to every registered user'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        RadioListTile<String>(
          value: 'specific_path',
          groupValue: _targetAudience,
          onChanged: (v) => setState(() => _targetAudience = v!),
          title: const Text('Specific Academic Path'),
          subtitle: const Text('Select grades, streams, or semesters'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        RadioListTile<String>(
          value: 'specific_users',
          groupValue: _targetAudience,
          onChanged: (v) => setState(() => _targetAudience = v!),
          title: const Text('Specific Users'),
          subtitle: const Text('Search and select individual users'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type = notification['type']?.toString() ?? 'system';
    final typeInfo = _notificationTypes[type] ?? _notificationTypes['system']!;
    final title = notification['title']?.toString() ?? '';
    final message = notification['message']?.toString() ?? '';
    final status = notification['status']?.toString() ?? '';
    final createdAt = notification['created_at']?.toString();
    final imageUrl = notification['image_url']?.toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeInfo.color.withOpacity(0.1),
          child: Icon(typeInfo.icon, color: typeInfo.color, size: 20),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusBadge(status),
                const SizedBox(width: 8),
                if (createdAt != null)
                  Text(_formatDate(createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                if (imageUrl != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.image, size: 12, color: Colors.grey[500]),
                ],
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'edit') _editNotification(notification);
            if (action == 'delete') _deleteNotification(notification);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'sent':
        color = Colors.green;
        label = 'Sent';
        break;
      case 'scheduled':
        color = Colors.orange;
        label = 'Scheduled';
        break;
      case 'draft':
        color = Colors.grey;
        label = 'Draft';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

// ============================================================
// HELPER CLASSES
// ============================================================

class _NotificationTypeInfo {
  final String label;
  final IconData icon;
  final Color color;
  _NotificationTypeInfo(this.label, this.icon, this.color);
}

class _PathOption {
  final String value;
  final String label;
  _PathOption(this.value, this.label);
}

// ============================================================
// STRING EXTENSION
// ============================================================

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}