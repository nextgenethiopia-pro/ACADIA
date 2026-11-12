import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/services/imgbb_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:acadia/src/core/blocs/auth/auth_bloc.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasNetworkError = false;
  String? _profilePhotoUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _isAdmin = false;
  final ImagePicker _picker = ImagePicker();

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
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      }
    } catch (e) {
      final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      final isAdmin = _hardcodedAdminEmails.contains(userEmail);

      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoading = false;
          if (!isAdmin) {
            _hasNetworkError = true;
            _errorMessage = 'Failed to load profile data.';
          }
        });
      }
      debugPrint('Error loading profile data: $e');
    }
  }

  // Upload profile photos through the shared ImgBB service so the endpoint,
  // multipart field names, API key configuration, and error parsing are
  // consistent with ACADIA's other ImgBB uploads.
  Future<String> _uploadToImgBB(String imagePath) {
    return ImgbbService.uploadImage(File(imagePath));
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

        // Upload to ImgBB
        final imageUrl = await _uploadToImgBB(pickedFile.path);
        
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
                      'Uploading to ImgBB: ${(_uploadProgress * 100).toInt()}%',
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
    final path = (_userPath ?? _userData?['academic_path'] ?? _userData?['academic_level'] ?? '').toString().toUpperCase();
    final grade = _userGrade ?? _userData?['grade']?.toString();
    final stream = (_userStream ?? _userData?['stream']?.toString() ?? '').toLowerCase();
    final year = _userData?['year']?.toString();
    final semester = _userData?['semester']?.toString();
    final track = (_userData?['track']?.toString() ?? '').toLowerCase();

    if (path == 'UNIVERSITY' || path.contains('UNIVERSITY')) {
      if (semester == '2') {
        final trackName = track == 'pre_engineering' ? 'Pre-Engineering' : 'Other Natural Science';
        return 'University Freshman - Semester 2 ($trackName)';
      }
      if (semester == '1') {
        final streamName = stream == 'social' ? 'Social Science' : 'Natural Science';
        return 'University Freshman - Semester 1 ($streamName)';
      }
      return 'University Student${year != null ? ' ($year)' : ''}';
    } else if (grade != null && grade.isNotEmpty) {
      if (grade == '11' || grade == '12') {
        final streamName = stream == 'social' ? 'Social Science' : 'Natural Science';
        return 'Grade $grade • $streamName';
      }
      return 'Grade $grade • General Program';
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
            color: AppColors.primary.withOpacity(0.1),
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
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
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
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
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
                color: Colors.black.withOpacity(0.02),
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
          color: themeColor.withOpacity(0.1),
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
          border: Border.all(color: Colors.red.withOpacity(0.1)),
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