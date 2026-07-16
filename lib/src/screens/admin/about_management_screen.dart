import 'package:flutter/material.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/widgets/common/gradient_button.dart';

class AboutManagementScreen extends StatefulWidget {
  const AboutManagementScreen({super.key});

  @override
  State<AboutManagementScreen> createState() => _AboutManagementScreenState();
}

class _AboutManagementScreenState extends State<AboutManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  
  // Controllers
  final _developerNameController = TextEditingController();
  final _developerEmailController = TextEditingController();
  final _telegramController = TextEditingController();
  final _telegramUrlController = TextEditingController();
  final _websiteController = TextEditingController();
  final _websiteUrlController = TextEditingController();
  final _facebookUrlController = TextEditingController();
  final _instagramUrlController = TextEditingController();
  final _twitterUrlController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  final _tiktokUrlController = TextEditingController();
  final _missionController = TextEditingController();
  final _visionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _copyrightYearController = TextEditingController();
  final _copyrightTextController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _developerNameController.dispose();
    _developerEmailController.dispose();
    _telegramController.dispose();
    _telegramUrlController.dispose();
    _websiteController.dispose();
    _websiteUrlController.dispose();
    _facebookUrlController.dispose();
    _instagramUrlController.dispose();
    _twitterUrlController.dispose();
    _youtubeUrlController.dispose();
    _tiktokUrlController.dispose();
    _missionController.dispose();
    _visionController.dispose();
    _descriptionController.dispose();
    _copyrightYearController.dispose();
    _copyrightTextController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _firebaseService.getAppSettings();
      
      if (settings != null) {
        final about = settings['about_content'] as Map<String, dynamic>? ?? {};
        
        _developerNameController.text = about['developer_name']?.toString() ?? 'NextGen Ethiopia PLC';
        _developerEmailController.text = about['developer_email']?.toString() ?? 'nextgenethiopia@gmail.com';
        _telegramController.text = about['telegram']?.toString() ?? '@acadia_support';
        _telegramUrlController.text = about['telegram_url']?.toString() ?? 'https://t.me/acadia_support';
        _websiteController.text = about['website']?.toString() ?? 'www.acadia.app';
        _websiteUrlController.text = about['website_url']?.toString() ?? 'https://www.acadia.app';
        _facebookUrlController.text = about['facebook_url']?.toString() ?? 'https://facebook.com/acadia.app';
        _instagramUrlController.text = about['instagram_url']?.toString() ?? 'https://instagram.com/acadia.app';
        _twitterUrlController.text = about['twitter_url']?.toString() ?? 'https://twitter.com/acadia_app';
        _youtubeUrlController.text = about['youtube_url']?.toString() ?? 'https://youtube.com/@acadia-app';
        _tiktokUrlController.text = about['tiktok_url']?.toString() ?? 'https://tiktok.com/@acadia_app';
        _missionController.text = settings['mission']?.toString() ?? '';
        _visionController.text = settings['vision']?.toString() ?? '';
        _descriptionController.text = about['description']?.toString() ?? '';
        _copyrightYearController.text = about['copyright_year']?.toString() ?? '2026';
        _copyrightTextController.text = about['copyright_text']?.toString() ?? 'All rights reserved.';
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error loading data: $e');
    }
  }

  Future<void> _saveData() async {
    setState(() => _isSaving = true);
    
    try {
      final aboutContent = {
        'developer_name': _developerNameController.text.trim(),
        'developer_email': _developerEmailController.text.trim(),
        'telegram': _telegramController.text.trim(),
        'telegram_url': _telegramUrlController.text.trim(),
        'website': _websiteController.text.trim(),
        'website_url': _websiteUrlController.text.trim(),
        'facebook_url': _facebookUrlController.text.trim(),
        'instagram_url': _instagramUrlController.text.trim(),
        'twitter_url': _twitterUrlController.text.trim(),
        'youtube_url': _youtubeUrlController.text.trim(),
        'tiktok_url': _tiktokUrlController.text.trim(),
        'description': _descriptionController.text.trim(),
        'copyright_year': _copyrightYearController.text.trim(),
        'copyright_text': _copyrightTextController.text.trim(),
        'last_updated': DateTime.now().toIso8601String(),
      };
      
      final currentSettings = await _firebaseService.getAppSettings() ?? {};
      currentSettings['about_content'] = aboutContent;
      currentSettings['mission'] = _missionController.text.trim();
      currentSettings['vision'] = _visionController.text.trim();
      
      await _firebaseService.updateAppSettings(currentSettings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('About content saved!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Error saving: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: AppBar(title: Text('About Management')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Developer Information', [
              _buildTextField(_developerNameController, 'Developer Name', 'NextGen Ethiopia PLC'),
              _buildTextField(_developerEmailController, 'Developer Email', 'nextgenethiopia@gmail.com', isEmail: true),
              _buildTextField(_telegramController, 'Telegram Username', '@acadia_support'),
              _buildTextField(_telegramUrlController, 'Telegram URL', 'https://t.me/acadia_support', isUrl: true),
              _buildTextField(_websiteController, 'Website Name', 'www.acadia.app'),
              _buildTextField(_websiteUrlController, 'Website URL', 'https://www.acadia.app', isUrl: true),
            ]),
            
            const SizedBox(height: 24),
            
            _buildSection('Mission & Vision', [
              _buildMultilineTextField(_missionController, 'Mission Statement', 'Enter mission...'),
              const SizedBox(height: 12),
              _buildMultilineTextField(_visionController, 'Vision Statement', 'Enter vision...'),
            ]),
            
            const SizedBox(height: 24),
            
            _buildSection('App Description', [
              _buildMultilineTextField(_descriptionController, 'Description', 'Enter app description...'),
            ]),
            
            const SizedBox(height: 24),
            
            _buildSection('Social Media Links', [
              _buildTextField(_facebookUrlController, 'Facebook URL', 'https://facebook.com/', isUrl: true),
              const SizedBox(height: 12),
              _buildTextField(_instagramUrlController, 'Instagram URL', 'https://instagram.com/', isUrl: true),
              const SizedBox(height: 12),
              _buildTextField(_twitterUrlController, 'Twitter/X URL', 'https://twitter.com/', isUrl: true),
              const SizedBox(height: 12),
              _buildTextField(_youtubeUrlController, 'YouTube URL', 'https://youtube.com/', isUrl: true),
              const SizedBox(height: 12),
              _buildTextField(_tiktokUrlController, 'TikTok URL', 'https://tiktok.com/', isUrl: true),
            ]),
            
            const SizedBox(height: 24),
            
            _buildSection('Copyright', [
              _buildTextField(_copyrightYearController, 'Copyright Year', '2026'),
              _buildTextField(_copyrightTextController, 'Copyright Text', 'All rights reserved.'),
            ]),
            
            const SizedBox(height: 32),
            
            GradientButton(
              text: 'SAVE CHANGES',
              onPressed: _saveData,
              isLoading: _isSaving,
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, 
      {bool isEmail = false, bool isUrl = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          suffixIcon: (isEmail || isUrl) && controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  onPressed: () {},
                )
              : null,
        ),
        keyboardType: isEmail ? TextInputType.emailAddress : (isUrl ? TextInputType.url : TextInputType.text),
      ),
    );
  }

  Widget _buildMultilineTextField(TextEditingController controller, String label, String hint) {
    return TextField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }
}