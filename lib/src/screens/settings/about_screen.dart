import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  static const Map<String, dynamic> _fallbackAboutContent = {
    'developer_name': 'NextGen Ethiopia PLC',
    'developer_email': 'nextgenethiopia@gmail.com',
    'developer_email_secondary': 'adminacadia@gmail.com',
    'website': 'nextgen-ethiopia.web.app',
    'website_url': 'https://nextgen-ethiopia.web.app',
    'telegram_channel': '@next_gen_ethiopia',
    'telegram_channel_url': 'https://t.me/next_gen_ethiopia',
    'telegram_private': '@firo_ye',
    'telegram_private_url': 'https://t.me/firo_ye',
    'acadia_telegram': '@acadia_app',
    'acadia_telegram_url': 'https://t.me/acadia_app',
    'acadia_support': '@acadia_supports',
    'acadia_support_url': 'https://t.me/acadia_supports',
    'youtube': '@acadia-app',
    'youtube_url': 'https://www.youtube.com/@acadia-app',
    'tiktok': '@acadia.app',
    'tiktok_url': 'https://www.tiktok.com/@acadia.app',
    'instagram': '@acadi_aapp',
    'instagram_url': 'https://www.instagram.com/acadi_aapp',
    'twitter': '@acadia_app',
    'twitter_url': 'https://twitter.com/acadia_app',
    'facebook': 'https://www.facebook.com/profile.php?id=61589113088662',
    'facebook_url':
        'https://www.facebook.com/profile.php?id=61589113088662',
    'copyright_year': '2026',
    'copyright_text':
        'All rights reserved. This application and its content are protected by copyright laws. Unauthorized reproduction or distribution is prohibited.',
    'description':
        'ACADIA is a digital education platform built for Ethiopian students, covering High School (Grades 9–12) and University levels with 6 content formats per chapter.',
    'terms_text':
        'ACADIA Terms of Service\n\n1. Acceptance of Terms\nBy using the ACADIA application, you agree to these terms of service.\n\n2. User Responsibilities\nUsers must provide accurate information and maintain account security.\n\n3. Content Usage\nAll content is for personal educational use only.\n\n4. Payment Terms\nPayments unlock grade packages for one year.\n\n5. Privacy Policy\nYour data is protected according to our privacy policy.',
  };

  static const String _fallbackMission =
      'To empower Ethiopian students through accessible, high-quality digital education that transcends traditional classroom boundaries.';
  static const String _fallbackVision =
      'To become Ethiopia\'s leading digital education platform, making quality learning accessible to every student across the nation.';

  Map<String, dynamic> _aboutContent = {};
  bool _isLoading = true;
  String? _missionText;
  String? _visionText;

  @override
  void initState() {
    super.initState();
    _loadAboutContent();
  }

  void _applyFallbackContent() {
    _aboutContent = Map<String, dynamic>.from(_fallbackAboutContent);
    _missionText = _fallbackMission;
    _visionText = _fallbackVision;
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
        if (mounted) {
          setState(() {
            _applyFallbackContent();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading about content: $e');
      if (mounted) {
        setState(() {
          _applyFallbackContent();
          _isLoading = false;
        });
      }
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Logo, app name and version
          _buildHeader(theme),
          const SizedBox(height: 24),

          // Slogan card
          _buildDescriptionSection(theme),
          const SizedBox(height: 20),

          // Mission & Vision
          if (_missionText != null || _visionText != null) ...[
            _buildMissionVisionSection(theme),
            const SizedBox(height: 20),
          ],

          // Contact & Support
          _buildContactSection(context),
          const SizedBox(height: 20),

          // Social media (real brand icons)
          _buildFollowSection(context),
          const SizedBox(height: 20),

          // Legal: copyright notice + terms + privacy
          _buildLegalSection(context, theme),
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
                  color: AppColors.primary.withOpacity(0.3),
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
              color: AppColors.primary.withOpacity(0.1),
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
          colors: [AppColors.primary.withOpacity(0.05), AppColors.secondary.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          if (_missionText != null) ...[
            Row(
              children: [
                const Icon(Icons.flag, color: AppColors.primary, size: 20),
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
                const Icon(Icons.visibility, color: AppColors.primary, size: 20),
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
        'Empowering Ethiopian Students Through Digital Education';

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
              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
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
        ],
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
            color: Colors.black.withOpacity(0.02),
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
                  color: color.withOpacity(0.1),
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
                color: AppColors.primary.withOpacity(0.1),
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


  Widget _buildContactSection(BuildContext context) {
    return _buildInfoCard(
      context,
      title: 'Contact & Support',
      icon: Icons.support_agent,
      color: Colors.blue,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logos/next_logo.jpg',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.business,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Developed by',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _aboutContent['developer_name'] ?? 'NextGen Ethiopia PLC',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildTile(
              icon: Icons.email,
              name: 'Email',
              onTap: () => _launchEmail(
                  _aboutContent['developer_email'] ?? 'nextgenethiopia@gmail.com'),
            ),
            _buildTile(
              icon: Icons.alternate_email,
              name: 'Admin Email',
              onTap: () => _launchEmail(_aboutContent['developer_email_secondary'] ??
                  'adminacadia@gmail.com'),
            ),
            _buildTile(
              asset: 'assets/icons/website_icon.png',
              icon: Icons.language,
              name: 'Website',
              onTap: () => _launchUrl(_aboutContent['website_url'] ??
                  'https://nextgen-ethiopia.web.app'),
            ),
            _buildTile(
              asset: 'assets/icons/telegram_icon.png',
              icon: Icons.send,
              name: 'Telegram',
              onTap: () => _launchUrl(_aboutContent['telegram_channel_url'] ??
                  'https://t.me/next_gen_ethiopia'),
            ),
            _buildTile(
              icon: Icons.help_outline,
              name: 'Help Center',
              onTap: () => context.push('/settings/help'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFollowSection(BuildContext context) {
    return _buildInfoCard(
      context,
      title: 'Follow Us',
      icon: Icons.share,
      color: Colors.purple,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildTile(
                asset: 'assets/icons/telegram_icon.png',
                name: 'Telegram',
                onTap: () => _launchUrl(_aboutContent['acadia_telegram_url'] ??
                    'https://t.me/acadia_app'),
              ),
              _buildTile(
                asset: 'assets/icons/facebook_icon.png',
                name: 'Facebook',
                onTap: () => _launchUrl(_aboutContent['facebook_url'] ??
                    'https://www.facebook.com/profile.php?id=61589113088662'),
              ),
              _buildTile(
                asset: 'assets/icons/instagram_icon.jpg',
                name: 'Instagram',
                onTap: () => _launchUrl(_aboutContent['instagram_url'] ??
                    'https://www.instagram.com/acadi_aapp'),
              ),
              _buildTile(
                asset: 'assets/icons/youtube_icon.png',
                name: 'YouTube',
                onTap: () => _launchUrl(_aboutContent['youtube_url'] ??
                    'https://www.youtube.com/@acadia-app'),
              ),
              _buildTile(
                asset: 'assets/icons/tiktok_icon.png',
                name: 'TikTok',
                onTap: () => _launchUrl(_aboutContent['tiktok_url'] ??
                    'https://www.tiktok.com/@acadia.app'),
              ),
              _buildTile(
                asset: 'assets/icons/twitter_png.png',
                name: 'X (Twitter)',
                onTap: () => _launchUrl(_aboutContent['twitter_url'] ??
                    'https://twitter.com/acadia_app'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalSection(BuildContext context, ThemeData theme) {
    return _buildInfoCard(
      context,
      title: 'Legal & Policies',
      icon: Icons.gavel,
      color: Colors.grey,
      children: [
        Row(
          children: [
            const Icon(Icons.copyright, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              'Copyright Notice',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '© ${_aboutContent['copyright_year'] ?? '2026'} ${_aboutContent['developer_name'] ?? 'NextGen Ethiopia PLC'}. ${_aboutContent['copyright_text'] ?? ''}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Divider(color: Colors.grey[200]),
        _buildInfoTile(
          icon: Icons.description,
          label: 'Terms of Service',
          value: 'Read',
          isLink: true,
          onTap: () => context.push('/settings/terms'),
        ),
        _buildInfoTile(
          icon: Icons.privacy_tip,
          label: 'Privacy Policy',
          value: 'Read',
          isLink: true,
          onTap: () => context.push('/settings/privacy'),
        ),
      ],
    );
  }

  /// Shared tile used by both "Contact & Support" and "Follow Us".
  ///
  /// Shows a branded asset icon when one is available, otherwise the given
  /// Material [icon], with the platform/section name underneath.
  Widget _buildTile({
    String? asset,
    IconData? icon,
    required String name,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: asset == null
                  ? Icon(
                      icon ?? Icons.public,
                      size: 30,
                      color: AppColors.primary,
                    )
                  : Image.asset(
                      asset,
                      width: 34,
                      height: 34,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        icon ?? Icons.public,
                        size: 30,
                        color: AppColors.primary,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String rawUrl) async {
    var url = rawUrl.trim();
    if (url.isEmpty) return;
    if (url.startsWith('@')) {
      url = 'https://t.me/${url.substring(1)}';
    } else if (!url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('mailto:') &&
        !url.startsWith('tel:')) {
      url = 'https://$url';
    }
    try {
      final uri = Uri.parse(url);
      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = false;
      }
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchEmail(String email) async {
    var cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return;
    if (cleanEmail.startsWith('mailto:')) cleanEmail = cleanEmail.substring(7);
    try {
      final uri = Uri.parse('mailto:$cleanEmail');
      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = false;
      }
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }
}