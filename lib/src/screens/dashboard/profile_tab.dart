import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:acadia/src/core/blocs/auth/auth_bloc.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _userData;
  String? _userGrade;
  String? _userStream;
  String? _userPath;
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _hasNetworkError = false;
  String? _profilePhotoUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _isAdmin = false;
  final ImagePicker _picker = ImagePicker();

  // FreeImage.host API Key
  static const String _freeImageApiKey = '6d207e02198a847aa98d0a2a901485a5';

  // Hardcoded admin emails - always have admin access
  static const List<String> _hardcodedAdminEmails = [
    'nextgenethiopia@gmail.com',
    'adminacadia@gmail.com',
    'firaoltadesa21@gmail.com',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _hasNetworkError = false;
        _errorMessage = null;
        if (!_isLoading) _isRefreshing = true;
      });
    }

    try {
      final firebaseService = FirebaseService();
      final prefs = await SharedPreferences.getInstance();

      _userGrade = prefs.getString('grade') ?? prefs.getString('selected_grade');
      _userStream = prefs.getString('stream') ?? prefs.getString('selected_stream');
      _userPath = prefs.getString('academic_path');

      final userProfile = await firebaseService.getUserProfile();

      // Check if user is admin
      final userEmail = userProfile?['email']?.toString() ??
          FirebaseAuth.instance.currentUser?.email ??
          '';
      bool isAdmin = _hardcodedAdminEmails.contains(userEmail);

      if (!isAdmin) {
        try {
          final settings = await firebaseService.getAppSettings();
          final adminEmails = List<String>.from(settings?['admin_emails'] ?? []);
          isAdmin = adminEmails.contains(userEmail);
        } catch (e) {
          debugPrint('Error fetching admin emails: $e');
        }
      }

      if (mounted) {
        setState(() {
          _userData = userProfile;
          _profilePhotoUrl = userProfile?['profile_photo_url']?.toString();
          _userStats = {
            'total_study_hours': userProfile?['total_study_hours'] ?? 0,
            'completed_content': userProfile?['completed_content'] ?? 0,
            'average_score': userProfile?['average_score'] ?? 0,
          };
          _isAdmin = isAdmin;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      final isAdmin = _hardcodedAdminEmails.contains(userEmail);

      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoading = false;
          _isRefreshing = false;
          if (!isAdmin) {
            _hasNetworkError = true;
            _errorMessage = 'Failed to load profile data.';
          }
        });
      }
      debugPrint('Error loading profile data: $e');
    }
  }

  // ============================================================
  // FREEIMAGE.HOST UPLOAD
  // ============================================================

  Future<String?> _uploadToFreeImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      
      const uploadUrl = 'https://freeimage.host/api/1/upload';
      
      final dio = Dio();
      final formData = FormData.fromMap({
        'key': _freeImageApiKey,
        'action': 'upload',
        'source': MultipartFile.fromBytes(
          bytes,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'format': 'json',
      });
      
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
        return response.data['image']['url'];
      } else {
        debugPrint('FreeImage.host upload failed: ${response.data}');
        throw Exception(response.data['status_txt'] ?? 'Upload failed');
      }
    } on DioException catch (e) {
      debugPrint('FreeImage.host Dio error: $e');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('FreeImage.host upload error: $e');
      rethrow;
    }
  }

  Future<void> _updateProfilePhoto(String imageUrl) async {
    try {
      final firebaseService = FirebaseService();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId != null) {
        await firebaseService.updateDocument('users', userId, {
          'profile_photo_url': imageUrl,
          'profile_photo_updated_at': DateTime.now().toIso8601String(),
        });
        
        if (mounted) {
          setState(() {
            _profilePhotoUrl = imageUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _isUploading = true;
          _uploadProgress = 0.0;
        });

        // Upload to FreeImage.host
        final imageUrl = await _uploadToFreeImage(pickedFile.path);
        
        if (imageUrl != null) {
          // Update user profile with new image URL
          await _updateProfilePhoto(imageUrl);
        }
        
        if (mounted) {
          setState(() {
            _isUploading = false;
            _uploadProgress = 0.0;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error picking/uploading image: $e');
    }
  }

  Future<void> _removeProfilePhoto() async {
    try {
      final firebaseService = FirebaseService();
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId != null) {
        await firebaseService.updateDocument('users', userId, {
          'profile_photo_url': null,
        });
        
        if (mounted) {
          setState(() {
            _profilePhotoUrl = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo removed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Update Profile Photo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            if (_isUploading)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading to FreeImage.host: ${(_uploadProgress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            if (_profilePhotoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getAcademicPathDisplay() {
    if (_userPath == 'high-school' || _userPath == 'HIGH SCHOOL') {
      final stream = _userStream == 'natural'
          ? 'Natural Science'
          : _userStream == 'social'
              ? 'Social Science'
              : '';
      return 'Grade ${_userGrade ?? '9-12'}${stream.isNotEmpty ? ' • $stream' : ''}';
    } else if (_userPath == 'university' || _userPath == 'UNIVERSITY') {
      return 'University Student';
    }
    return _userPath ?? 'Education Path Not Set';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasNetworkError && !_isAdmin) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              const Text('Connection Error',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_errorMessage ?? '',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final userName = _userData?['full_name']?.toString() ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'Student';
    final userEmail = _userData?['email']?.toString() ??
        FirebaseAuth.instance.currentUser?.email ??
        '';
    final isPro = _userData?['is_pro'] == true;
    final studyTime = '${_userStats?['total_study_hours'] ?? 0}';
    final completed = '${_userStats?['completed_content'] ?? 0}';
    final successRate = '${_userStats?['average_score'] ?? 0}%';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withBlue(200)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                    child: Column(
                      children: [
                        _buildProfileCard(userName, userEmail, isPro),
                        const SizedBox(height: 24),
                        _buildStatsGrid(studyTime, completed, successRate),
                        const SizedBox(height: 32),
                        _buildActionMenu(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String name, String email, bool isPro) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(((255 * 0.1)).toInt()),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: _showPhotoOptions,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Colors.blueAccent],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: _profilePhotoUrl != null
                        ? NetworkImage(_profilePhotoUrl!)
                        : null,
                    child: _profilePhotoUrl == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _showPhotoOptions,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(((255 * 0.05)).toInt()),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.primary.withAlpha(((255 * 0.1)).toInt())),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_rounded,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _getAcademicPathDisplay(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPro) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(((255 * 0.1)).toInt()),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.amber.withAlpha(((255 * 0.3)).toInt())),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(String time, String completed, String success) {
    return Row(
      children: [
        _buildStatItem('Study Hours', time, Icons.auto_graph_rounded, Colors.blue),
        const SizedBox(width: 12),
        _buildStatItem('Lessons', completed, Icons.menu_book_rounded, Colors.orange),
        const SizedBox(width: 12),
        _buildStatItem('Avg. Score', success, Icons.analytics_rounded, Colors.purple),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(((255 * 0.03)).toInt()),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(((255 * 0.1)).toInt()),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenu() {
    return Column(
      children: [
        // Admin Panel
        if (_isAdmin) ...[
          _buildMenuSection('ADMIN PANEL', [
            _buildMenuTile(Icons.dashboard_customize, 'Admin Dashboard',
                () => context.push('/admin/dashboard'),
                color: Colors.indigo),
            _buildMenuTile(Icons.folder_open, 'Content Management',
                () => context.push('/admin/content-management'),
                color: Colors.teal),
            _buildMenuTile(Icons.people, 'User Management',
                () => context.push('/admin/user-management'),
                color: Colors.purple),
            _buildMenuTile(Icons.payment, 'Payment Approval',
                () => context.push('/admin/payment-approval'),
                color: Colors.green),
            _buildMenuTile(Icons.notifications, 'Create Notification',
                () => context.push('/admin/create-notification'),
                color: Colors.orange),
            _buildMenuTile(Icons.analytics, 'Analytics Dashboard',
                () => context.push('/admin/analytics'),
                color: Colors.red),
            _buildMenuTile(Icons.school, 'Entrance Management',
                () => context.push('/admin/entrance-management'),
                color: Colors.brown),
            _buildMenuTile(Icons.settings, 'App Settings',
                () => context.push('/admin/app-settings'),
                color: Colors.grey),
            _buildMenuTile(Icons.info, 'About Management',
                () => context.push('/admin/about-management'),
                color: Colors.cyan),
          ]),
          const SizedBox(height: 12),
        ],

        // Account
        _buildMenuSection('ACCOUNT', [
          _buildMenuTile(Icons.person_outline, 'Edit Profile',
              () => context.push('/settings/edit-profile')),
          _buildMenuTile(Icons.payment, 'Payment History',
              () => context.push('/payment-history')),
          _buildMenuTile(Icons.download, 'Downloads',
              () => context.push('/settings/downloads')),
        ]),
        const SizedBox(height: 12),

        // Settings
        _buildMenuSection('SETTINGS', [
          _buildMenuTile(Icons.settings, 'App Settings',
              () => context.push('/settings')),
          _buildMenuTile(Icons.lock_outline, 'Change Password',
              () => context.push('/settings/change-password')),
        ]),
        const SizedBox(height: 12),

        // Support
        _buildMenuSection('SUPPORT', [
          _buildMenuTile(Icons.help_outline, 'Help Center',
              () => context.push('/settings/help')),
          _buildMenuTile(Icons.info_outline, 'About ACADIA',
              () => context.push('/settings/about')),
        ]),
        const SizedBox(height: 32),

        // Sign Out
        _buildSignOutButton(),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey[400],
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(((255 * 0.02)).toInt()),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    final themeColor = color ?? Colors.grey[800]!;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: themeColor.withAlpha(((255 * 0.1)).toInt()),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: themeColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          color: Colors.black12, size: 14),
    );
  }

  Widget _buildSignOutButton() {
    return InkWell(
      onTap: () {
        context.read<AuthBloc>().add(const AuthSignOutRequested());
        context.go('/welcome');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.withAlpha(((255 * 0.1)).toInt())),
        ),
        child: const Center(
          child: Text(
            'Sign Out',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}