import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final _developerEmailSecondaryController = TextEditingController();
  final _websiteController = TextEditingController();
  final _websiteUrlController = TextEditingController();
  final _telegramChannelController = TextEditingController();
  final _telegramChannelUrlController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _tiktokUrlController = TextEditingController();
  final _instagramController = TextEditingController();
  final _instagramUrlController = TextEditingController();
  final _twitterController = TextEditingController();
  final _twitterUrlController = TextEditingController();
  final _facebookController = TextEditingController();
  final _facebookUrlController = TextEditingController();

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
    _developerEmailSecondaryController.dispose();
    _websiteController.dispose();
    _websiteUrlController.dispose();
    _telegramChannelController.dispose();
    _telegramChannelUrlController.dispose();
    _youtubeController.dispose();
    _youtubeUrlController.dispose();
    _tiktokController.dispose();
    _tiktokUrlController.dispose();
    _instagramController.dispose();
    _instagramUrlController.dispose();
    _twitterController.dispose();
    _twitterUrlController.dispose();
    _facebookController.dispose();
    _facebookUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _firebaseService.getAppSettings();

      if (settings != null) {
        final about = settings['about_content'] as Map<String, dynamic>? ?? {};

        _developerNameController.text =
            about['developer_name']?.toString() ?? 'NextGen Ethiopia PLC';
        _developerEmailController.text =
            about['developer_email']?.toString() ?? 'nextgenethiopia@gmail.com';
        _developerEmailSecondaryController.text =
            about['developer_email_secondary']?.toString() ?? 'dev@nextgenethiopia.com';
        _websiteController.text =
            about['website']?.toString() ?? 'nextgen-ethiopia.web.app';
        _websiteUrlController.text = about['website_url']?.toString() ??
            'https://nextgen-ethiopia.web.app';
        _telegramChannelController.text =
            about['telegram_channel']?.toString() ?? '@next_gen_ethiopia';
        _telegramChannelUrlController.text =
            about['telegram_channel_url']?.toString() ?? 'https://t.me/next_gen_ethiopia';
        _youtubeController.text =
            about['youtube']?.toString() ?? '@acadia-app';
        _youtubeUrlController.text =
            about['youtube_url']?.toString() ?? 'https://www.youtube.com/@acadia-app';
        _tiktokController.text =
            about['tiktok']?.toString() ?? '@acadia.app';
        _tiktokUrlController.text =
            about['tiktok_url']?.toString() ?? 'https://www.tiktok.com/@acadia.app';
        _instagramController.text =
            about['instagram']?.toString() ?? '@acadi_aapp';
        _instagramUrlController.text =
            about['instagram_url']?.toString() ?? 'https://www.instagram.com/acadi_aapp';
        _twitterController.text =
            about['twitter']?.toString() ?? '@acadia_app';
        _twitterUrlController.text =
            about['twitter_url']?.toString() ?? 'https://twitter.com/acadia_app';
        _facebookController.text =
            about['facebook']?.toString() ?? 'https://www.facebook.com/profile.php?id=61589113088662';
        _facebookUrlController.text =
            about['facebook_url']?.toString() ?? 'https://www.facebook.com/profile.php?id=61589113088662';
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
        'developer_email_secondary': _developerEmailSecondaryController.text.trim(),
        'website': _websiteController.text.trim(),
        'website_url': _websiteUrlController.text.trim(),
        'telegram_channel': _telegramChannelController.text.trim(),
        'telegram_channel_url': _telegramChannelUrlController.text.trim(),
        'youtube': _youtubeController.text.trim(),
        'youtube_url': _youtubeUrlController.text.trim(),
        'tiktok': _tiktokController.text.trim(),
        'tiktok_url': _tiktokUrlController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'instagram_url': _instagramUrlController.text.trim(),
        'twitter': _twitterController.text.trim(),
        'twitter_url': _twitterUrlController.text.trim(),
        'facebook': _facebookController.text.trim(),
        'facebook_url': _facebookUrlController.text.trim(),
        'last_updated': DateTime.now().toIso8601String(),
      };

      final currentSettings = await _firebaseService.getAppSettings() ?? {};
      currentSettings['about_content'] = aboutContent;

      await _firebaseService.updateAppSettings(currentSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('About content saved!'),
              backgroundColor: Colors.green),
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
      return Scaffold(
        appBar: AppBar(title: const Text('About Management')),
        body: const Center(child: CircularProgressIndicator()),
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
              _buildTextField(_developerNameController, 'Developer Name',
                  'NextGen Ethiopia PLC'),
              _buildTextField(_developerEmailController, 'Developer Email',
                  'nextgenethiopia@gmail.com',
                  isEmail: true),
              _buildTextField(_developerEmailSecondaryController, 'Secondary Email',
                  'dev@nextgenethiopia.com',
                  isEmail: true),
              _buildTextField(
                  _telegramChannelController, 'Telegram Channel', '@next_gen_ethiopia'),
              _buildTextField(_telegramChannelUrlController, 'Telegram Channel URL',
                  'https://t.me/next_gen_ethiopia',
                  isUrl: true),
              _buildTextField(_websiteController, 'Website Name',
                  'nextgen-ethiopia.web.app'),
              _buildTextField(_websiteUrlController, 'Website URL',
                  'https://nextgen-ethiopia.web.app',
                  isUrl: true),
            ]),
            const SizedBox(height: 24),
            _buildSection('Social Media Links', [
              _buildTextField(_facebookController, 'Facebook',
                  'https://www.facebook.com/'),
              _buildTextField(_facebookUrlController, 'Facebook URL',
                  'https://www.facebook.com/',
                  isUrl: true),
              const SizedBox(height: 12),
              _buildTextField(_instagramController, 'Instagram',
                  '@acadi_aapp'),
              _buildTextField(_instagramUrlController, 'Instagram URL',
                  'https://www.instagram.com/',
                  isUrl: true),
              const SizedBox(height: 12),
              _buildTextField(_twitterController, 'Twitter/X',
                  '@acadia_app'),
              _buildTextField(_twitterUrlController, 'Twitter/X URL',
                  'https://twitter.com/',
                  isUrl: true),
              const SizedBox(height: 12),
              _buildTextField(
                  _youtubeController, 'YouTube', '@acadia-app'),
              _buildTextField(
                  _youtubeUrlController, 'YouTube URL', 'https://youtube.com/',
                  isUrl: true),
              const SizedBox(height: 12),
              _buildTextField(
                  _tiktokController, 'TikTok', '@acadia.app'),
              _buildTextField(
                  _tiktokUrlController, 'TikTok URL', 'https://tiktok.com/',
                  isUrl: true),
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
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint,
      {bool isEmail = false, bool isUrl = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: isEmail
            ? TextInputType.emailAddress
            : (isUrl ? TextInputType.url : TextInputType.text),
      ),
    );
  }
}
