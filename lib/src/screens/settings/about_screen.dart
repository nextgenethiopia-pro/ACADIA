import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/constants/app_constants.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  Map<String, dynamic> _aboutContent = {};
  bool _isLoading = true;
  String? _missionText;
  String? _visionText;

  @override
  void initState() {
    super.initState();
    _loadAboutContent();
  }

  Future<void> _loadAboutContent() async {
    try {
      final firebaseService = FirebaseService();
      final contentData = await firebaseService.getAppSettings();

      if (contentData != null && contentData['about_content'] != null) {
        if (mounted) {
          setState(() {
            _aboutContent = Map<String, dynamic>.from(contentData['about_content']);
            _missionText = contentData['mission']?.toString();
            _visionText = contentData['vision']?.toString();
            _isLoading = false;
          });
        }
      } else {
        // Default content from ACADIA spec
        if (mounted) {
          setState(() {
            _aboutContent = {
              'developer_name': 'NextGen Ethiopia PLC',
              'developer_email': 'nextgenethiopia@gmail.com',
              'telegram': '@acadia_support',
              'telegram_url': 'https://t.me/acadia_support',
              'website': 'www.acadia.app',
              'website_url': 'https://www.acadia.app',
              'facebook_url': 'https://facebook.com/acadia.app',
              'instagram_url': 'https://instagram.com/acadia.app',
              'twitter_url': 'https://twitter.com/acadia_app',
              'youtube_url': 'https://youtube.com/@acadia-app',
              'tiktok_url': 'https://tiktok.com/@acadia_app',
              'copyright_year': '2026',
              'copyright_text': 'All rights reserved. This application and its content are protected by copyright laws. Unauthorized reproduction or distribution is prohibited.',
              'description': 'ACADIA is a digital education platform built for Ethiopian students, covering High School (Grades 9–12) and University levels with 6 content formats per chapter.',
              'terms_text': 'ACADIA Terms of Service\n\n1. Acceptance of Terms\nBy using the ACADIA application, you agree to these terms of service.\n\n2. User Responsibilities\nUsers must provide accurate information and maintain account security.\n\n3. Content Usage\nAll content is for personal educational use only.\n\n4. Payment Terms\nPayments unlock grade packages for one year.\n\n5. Privacy Policy\nYour data is protected according to our privacy policy.',
            };
            _missionText = 'To empower Ethiopian students through accessible, high-quality digital education that transcends traditional classroom boundaries.';
            _visionText = 'To become Ethiopia\'s leading digital education platform, making quality learning accessible to every student across the nation.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading about content: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('About')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('About ACADIA'),
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Logo and App Info
          _buildHeader(theme),
          const SizedBox(height: 24),

          // Mission & Vision
          if (_missionText != null || _visionText != null)
            _buildMissionVisionSection(theme),
          const SizedBox(height: 24),

          // Description
          _buildDescriptionSection(theme),
          const SizedBox(height: 24),

          // Developer Information
          _buildInfoCard(
            context,
            title: 'Developer Information',
            icon: Icons.business_center,
            color: Colors.blue,
            children: [
              _buildInfoTile(
                icon: Icons.business,
                label: 'Developer',
                value: _aboutContent['developer_name'] ?? 'NextGen Ethiopia PLC',
              ),
              _buildInfoTile(
                icon: Icons.email,
                label: 'Email',
                value: _aboutContent['developer_email'] ?? '',
                isLink: true,
                onTap: () => _launchEmail(_aboutContent['developer_email'] ?? ''),
              ),
              _buildInfoTile(
                icon: Icons.telegram,
                label: 'Telegram',
                value: _aboutContent['telegram'] ?? '@acadia_support',
                isLink: true,
                onTap: () => _launchUrl(_aboutContent['telegram_url'] ?? ''),
              ),
              _buildInfoTile(
                icon: Icons.language,
                label: 'Website',
                value: _aboutContent['website'] ?? 'www.acadia.app',
                isLink: true,
                onTap: () => _launchUrl(_aboutContent['website_url'] ?? ''),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Social Media
          _buildInfoCard(
            context,
            title: 'Connect With Us',
            icon: Icons.share,
            color: Colors.purple,
            children: _buildSocialLinks(),
          ),
          const SizedBox(height: 24),

          // Copyright Notice
          _buildInfoCard(
            context,
            title: 'Copyright Notice',
            icon: Icons.copyright,
            color: Colors.grey,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '© ${_aboutContent['copyright_year'] ?? '2026'} ${_aboutContent['developer_name'] ?? 'NextGen Ethiopia PLC'}. ${_aboutContent['copyright_text'] ?? ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _showTermsDialog(context),
                icon: const Icon(Icons.description, size: 18),
                label: const Text('View Full Terms of Service'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showPrivacyDialog(context),
                icon: const Icon(Icons.privacy_tip, size: 18),
                label: const Text('View Privacy Policy'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(((255 * 0.3)).toInt()),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/logos/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.school,
                    size: 50,
                    color: Colors.white,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.appName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(((255 * 0.1)).toInt()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Version ${AppConstants.appVersion}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppConstants.tagline,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMissionVisionSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withAlpha(((255 * 0.05)).toInt()), AppColors.secondary.withAlpha(((255 * 0.02)).toInt())],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(((255 * 0.1)).toInt())),
      ),
      child: Column(
        children: [
          if (_missionText != null) ...[
            Row(
              children: [
                Icon(Icons.flag, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Our Mission',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _missionText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_visionText != null) ...[
            Row(
              children: [
                Icon(Icons.visibility, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Our Vision',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _visionText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(ThemeData theme) {
    final description = _aboutContent['description']?.toString() ?? 
        'ACADIA is a digital education platform built for Ethiopian students, covering High School (Grades 9–12) and University levels with 6 content formats per chapter.';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'About ACADIA',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeatureChip('📚 6 Content Types'),
              _buildFeatureChip('📱 Offline First'),
              _buildFeatureChip('🎥 Video Lessons'),
              _buildFeatureChip('📝 Short Notes'),
              _buildFeatureChip('❓ Quizzes'),
              _buildFeatureChip('📋 Exams'),
              _buildFeatureChip('🃏 Flashcards'),
              _buildFeatureChip('📄 Past Papers'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(((255 * 0.1)).toInt()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(((255 * 0.02)).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(((255 * 0.1)).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(((255 * 0.1)).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isLink ? AppColors.primary : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (isLink)
              const Icon(Icons.open_in_new, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSocialLinks() {
    final socialLinks = [
      {'icon': 'assets/icons/telegram_icon.png', 'label': 'Telegram', 'url': _aboutContent['telegram_url']},
      {'icon': 'assets/icons/facebook_icon.png', 'label': 'Facebook', 'url': _aboutContent['facebook_url']},
      {'icon': 'assets/icons/instagram_icon.jpg', 'label': 'Instagram', 'url': _aboutContent['instagram_url']},
      {'icon': 'assets/icons/twitter_png.png', 'label': 'Twitter', 'url': _aboutContent['twitter_url']},
      {'icon': 'assets/icons/youtube_icon.png', 'label': 'YouTube', 'url': _aboutContent['youtube_url']},
      {'icon': 'assets/icons/tiktok_icon.png', 'label': 'TikTok', 'url': _aboutContent['tiktok_url']},
    ];

    return socialLinks.where((link) => link['url'] != null && link['url'].toString().isNotEmpty).map((link) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Image.asset(
            link['icon'] as String,
            width: 28,
            height: 28,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(((255 * 0.1)).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.link, color: AppColors.primary, size: 16),
              );
            },
          ),
          title: Text(
            link['label'] as String,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () => _launchUrl(link['url'].toString()),
        ),
      );
    }).toList();
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Text(
            _aboutContent['terms_text'] ?? 'Terms of Service content not available.',
            style: const TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    final privacyText = _aboutContent['privacy_text'] ?? 
        'ACADIA Privacy Policy\n\n'
        '1. Information Collection\nWe collect information you provide during registration including name, email, phone number, and academic information.\n\n'
        '2. Data Usage\nYour data is used to provide personalized educational content and track your progress.\n\n'
        '3. Data Security\nWe implement industry-standard security measures to protect your data.\n\n'
        '4. Third-Party Sharing\nWe do not sell or share your personal information with third parties.\n\n'
        '5. Your Rights\nYou have the right to access, modify, or delete your personal data.\n\n'
        'For questions, contact us at nextgenethiopia@gmail.com';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            privacyText,
            style: const TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    if (email.isEmpty) return;
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}