import 'dart:io';
import 'package:flutter/material.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

class ImageManagementScreen extends StatefulWidget {
  const ImageManagementScreen({super.key});

  @override
  State<ImageManagementScreen> createState() => _ImageManagementScreenState();
}

class _ImageManagementScreenState extends State<ImageManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();
  
  // FreeImage.host API Key
  static const String _freeImageApiKey = '6d207e02198a847aa98d0a2a901485a5';
  
  // Image configurations
  List<ImageConfig> _images = [];
  bool _isLoading = true;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadingImageId;
  
  @override
  void initState() {
    super.initState();
    _loadImages();
  }
  
  Future<void> _loadImages() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _firebaseService.getAppSettings();
      
      // Define all images that can be managed
      _images = [
        ImageConfig(
          id: 'app_logo',
          title: 'App Logo',
          description: 'Main app logo displayed in splash screen and app bar',
          currentUrl: settings?['app_logo']?.toString(),
          category: ImageCategory.logo,
          recommendedSize: '512x512',
          format: 'PNG',
        ),
        ImageConfig(
          id: 'splash_image',
          title: 'Splash Screen Background',
          description: 'Background image shown during app loading (splash.jpg)',
          currentUrl: settings?['splash_image']?.toString(),
          category: ImageCategory.splash,
          recommendedSize: '1080x1920',
          format: 'JPG/PNG',
        ),
        ImageConfig(
          id: 'splash_image_2',
          title: 'Splash Image 2',
          description: 'Optional second splash image (cycles if multiple)',
          currentUrl: settings?['splash_image_2']?.toString(),
          category: ImageCategory.splash,
          recommendedSize: '1080x1920',
          format: 'JPG/PNG',
        ),
        ImageConfig(
          id: 'splash_image_3',
          title: 'Splash Image 3',
          description: 'Optional third splash image (cycles if multiple)',
          currentUrl: settings?['splash_image_3']?.toString(),
          category: ImageCategory.splash,
          recommendedSize: '1080x1920',
          format: 'JPG/PNG',
        ),
        ImageConfig(
          id: 'welcome_image',
          title: 'Welcome Screen Image',
          description: 'Main image shown on welcome screen carousel',
          currentUrl: settings?['welcome_image']?.toString(),
          category: ImageCategory.welcome,
          recommendedSize: '800x600',
          format: 'JPG/PNG',
        ),
        ImageConfig(
          id: 'popup_image',
          title: 'How-To Popup Image',
          description: 'Image shown in the how-to tutorial popup',
          currentUrl: settings?['popup_image']?.toString(),
          category: ImageCategory.popup,
          recommendedSize: '400x400',
          format: 'PNG',
        ),
        ImageConfig(
          id: 'empty_state_image',
          title: 'Empty State Image',
          description: 'Image shown when no content is available',
          currentUrl: settings?['empty_state_image']?.toString(),
          category: ImageCategory.general,
          recommendedSize: '400x400',
          format: 'PNG',
        ),
        ImageConfig(
          id: 'error_image',
          title: 'Error State Image',
          description: 'Image shown when an error occurs',
          currentUrl: settings?['error_image']?.toString(),
          category: ImageCategory.general,
          recommendedSize: '400x400',
          format: 'PNG',
        ),
      ];
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading images: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
          filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'format': 'json',
      });
      
      final response = await dio.post(
        uploadUrl,
        data: formData,
        onSendProgress: (sent, total) {
          if (mounted && _uploadingImageId != null) {
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
  
  Future<void> _uploadImage(ImageConfig image) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (pickedFile == null) return;
      
      setState(() {
        _isUploading = true;
        _uploadingImageId = image.id;
        _uploadProgress = 0.0;
      });
      
      final imageFile = File(pickedFile.path);
      final imageUrl = await _uploadToFreeImage(imageFile);
      
      if (imageUrl == null) {
        throw Exception('Upload failed');
      }
      
      // Update Firebase settings
      final settings = await _firebaseService.getAppSettings() ?? {};
      settings[image.id] = imageUrl;
      await _firebaseService.updateAppSettings(settings);
      
      // Update local state
      setState(() {
        image.currentUrl = imageUrl;
        _isUploading = false;
        _uploadingImageId = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${image.title} updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadingImageId = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Future<void> _deleteImage(ImageConfig image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${image.title}'),
        content: Text('Are you sure you want to remove ${image.title}?'),
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
    
    if (confirmed != true) return;
    
    try {
      final settings = await _firebaseService.getAppSettings() ?? {};
      settings.remove(image.id);
      await _firebaseService.updateAppSettings(settings);
      
      setState(() {
        image.currentUrl = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${image.title} removed'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  void _previewImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.black87,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  url,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 16,
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
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Management'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF1A237E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.image, color: Colors.white, size: 32),
                        const SizedBox(height: 8),
                        const Text(
                          'Manage App Images',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upload and manage images for splash screen, logo, welcome screen, and more',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Images by category
                  _buildCategorySection(ImageCategory.logo, theme),
                  const SizedBox(height: 24),
                  _buildCategorySection(ImageCategory.splash, theme),
                  const SizedBox(height: 24),
                  _buildCategorySection(ImageCategory.welcome, theme),
                  const SizedBox(height: 24),
                  _buildCategorySection(ImageCategory.popup, theme),
                  const SizedBox(height: 24),
                  _buildCategorySection(ImageCategory.general, theme),
                ],
              ),
            ),
    );
  }
  
  Widget _buildCategorySection(ImageCategory category, ThemeData theme) {
    final categoryImages = _images.where((img) => img.category == category).toList();
    if (categoryImages.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getCategoryTitle(category),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...categoryImages.map((image) => _buildImageCard(image, theme)),
      ],
    );
  }
  
  Widget _buildImageCard(ImageConfig image, ThemeData theme) {
    final isUploading = _isUploading && _uploadingImageId == image.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: image.currentUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            image.currentUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image, size: 30, color: Colors.grey);
                            },
                          ),
                        )
                      : Center(
                          child: Icon(Icons.image, size: 30, color: Colors.grey[400]),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        image.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        image.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'Recommended: ${image.recommendedSize} (${image.format})',
                            style: TextStyle(color: Colors.grey[500], fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isUploading)
              Column(
                children: [
                  LinearProgressIndicator(value: _uploadProgress),
                  const SizedBox(height: 8),
                  Text('Uploading: ${(_uploadProgress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (image.currentUrl != null)
                  TextButton.icon(
                    onPressed: () => _previewImage(image.currentUrl!),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Preview'),
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _uploadImage(image),
                  icon: const Icon(Icons.cloud_upload, size: 18),
                  label: Text(image.currentUrl != null ? 'Replace' : 'Upload'),
                ),
                if (image.currentUrl != null)
                  const SizedBox(width: 8),
                if (image.currentUrl != null)
                  TextButton.icon(
                    onPressed: () => _deleteImage(image),
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    label: const Text('Remove', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getCategoryTitle(ImageCategory category) {
    switch (category) {
      case ImageCategory.logo: return 'App Logo';
      case ImageCategory.splash: return 'Splash Screen Images';
      case ImageCategory.welcome: return 'Welcome Screen';
      case ImageCategory.popup: return 'Popup Tutorial';
      case ImageCategory.general: return 'General Images';
    }
  }
}

// ============================================================
// Helper Classes
// ============================================================

enum ImageCategory {
  logo,
  splash,
  welcome,
  popup,
  general,
}

class ImageConfig {
  final String id;
  final String title;
  final String description;
  String? currentUrl;
  final ImageCategory category;
  final String recommendedSize;
  final String format;
  
  ImageConfig({
    required this.id,
    required this.title,
    required this.description,
    this.currentUrl,
    required this.category,
    required this.recommendedSize,
    required this.format,
  });
}