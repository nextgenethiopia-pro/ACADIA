import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:acadia/src/widgets/common/gradient_button.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  // FreeImage.host API Key
  static const String _freeImageApiKey = '6d207e02198a847aa98d0a2a901485a5';

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isRefreshing = false;
  String? _profilePictureUrl;
  bool _isUploadingProfile = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  bool _hasNetworkError = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (mounted) {
      setState(() {
        _hasNetworkError = false;
        _errorMessage = null;
        if (!_isLoading) _isRefreshing = true;
      });
    }

    try {
      final firebaseService = FirebaseService();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userData = await firebaseService.getUserProfile();

        if (mounted) {
          setState(() {
            _userData = userData;
            _fullNameController.text = userData?['full_name'] ?? user.displayName ?? '';
            _profilePictureUrl = userData?['profile_photo_url']?.toString();
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
          _errorMessage = 'Failed to load profile data. Please check your connection.';
        });
        
        _showErrorSnackBar(_errorMessage!);
      }
      debugPrint('Error loading user data: $e');
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
          onPressed: _loadUserData,
        ),
      ),
    );
  }

  Future<String?> _uploadToFreeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
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
        return null;
      }
    } catch (e) {
      debugPrint('FreeImage.host upload error: $e');
      return null;
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
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isUploadingProfile = true;
          _uploadProgress = 0.0;
        });
        
        final imageFile = File(image.path);
        
        // Upload to FreeImage.host
        final imageUrl = await _uploadToFreeImage(imageFile);
        
        if (imageUrl != null) {
          // Update user profile with new image URL
          await _updateProfilePhoto(imageUrl);
          
          if (mounted) {
            setState(() {
              _profilePictureUrl = imageUrl;
              _isUploadingProfile = false;
              _uploadProgress = 0.0;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Upload failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingProfile = false;
          _uploadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeProfilePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Profile Photo'),
        content: const Text('Are you sure you want to remove your profile photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final firebaseService = FirebaseService();
        final userId = FirebaseAuth.instance.currentUser?.uid;
        
        if (userId != null) {
          await firebaseService.updateDocument('users', userId, {
            'profile_photo_url': null,
          });
          
          if (mounted) {
            setState(() {
              _profilePictureUrl = null;
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
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final firebaseService = FirebaseService();
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        await firebaseService.updateDocument('users', userId, {
          'full_name': _fullNameController.text.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // Update display name in Firebase Auth
        final user = FirebaseAuth.instance.currentUser;
        await user?.updateDisplayName(_fullNameController.text.trim());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    if (_hasNetworkError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Connection Error',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Unable to load profile data',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadUserData,
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
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    final phoneNumber = _userData?['phone']?.toString() ?? user?.phoneNumber ?? '';
    final formattedPhone = phoneNumber.startsWith('+251') 
        ? phoneNumber 
        : (phoneNumber.isNotEmpty ? '+251$phoneNumber' : 'Not provided');
    final email = user?.email ?? _userData?['email']?.toString() ?? '';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isUploadingProfile ? null : _pickProfileImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha((255 * 0.3).toInt()),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                                  ? Image.network(
                                      _profilePictureUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildDefaultAvatar();
                                      },
                                    )
                                  : _buildDefaultAvatar(),
                            ),
                          ),
                          if (_isUploadingProfile)
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        value: _uploadProgress,
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(_uploadProgress * 100).toInt()}%',
                                        style: const TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha((255 * 0.2).toInt()),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_profilePictureUrl != null)
                      TextButton(
                        onPressed: _removeProfilePhoto,
                        child: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Edit Your Profile',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Update your name and profile picture',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Full Name
              Text(
                'Full Name',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Email (Disabled)
              Text(
                'Email',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: email,
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email cannot be changed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),

              // Phone Number (Disabled)
              Text(
                'Phone Number',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: formattedPhone,
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Phone number cannot be changed after registration. Contact support if you need to update it.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              GradientButton(
                text: _isSaving ? 'SAVING...' : 'SAVE CHANGES',
                isLoading: _isSaving,
                onPressed: _saveChanges,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF1A237E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.person,
          size: 50,
          color: Colors.white,
        ),
      ),
    );
  }
}