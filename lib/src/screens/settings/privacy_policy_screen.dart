import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/services/firebase_service.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  Map<String, dynamic> _privacyContent = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasNetworkError = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  Future<void> _loadPrivacyPolicy() async {
    setState(() {
      _isLoading = true;
      _hasNetworkError = false;
      _errorMessage = null;
    });

    try {
      final firebaseService = FirebaseService();
      final settings = await firebaseService.getAppSettings();

      if (settings != null && settings['privacy_policy'] != null) {
        if (mounted) {
          setState(() {
            _privacyContent = Map<String, dynamic>.from(settings['privacy_policy']);
            _isLoading = false;
          });
        }
      } else {
        // Default privacy policy content
        if (mounted) {
          setState(() {
            _privacyContent = {
              'title': 'Privacy Policy',
              'last_updated': 'May 2026',
              'sections': [
                {
                  'title': '1. Introduction',
                  'content': 'ACADIA ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our educational application. By using ACADIA, you consent to the data practices described in this policy.',
                },
                {
                  'title': '2. Information We Collect',
                  'content': '• Personal Information: Name, email address, phone number, academic path (grade, stream, university)\n• Usage Data: Study time, completed content, quiz scores, progress tracking\n• Device Information: Device type, operating system, app version, device identifiers',
                },
                {
                  'title': '3. How We Use Your Information',
                  'content': '• To provide and maintain our educational services\n• To track your learning progress and provide personalized recommendations\n• To communicate with you about updates, promotions, and support\n• To improve our application and user experience\n• To process payments and verify transactions',
                },
                {
                  'title': '4. Data Storage and Security',
                  'content': 'We implement appropriate technical and organizational security measures to protect your personal information from unauthorized access, alteration, disclosure, or destruction. Your data is stored securely using Firebase Firestore and local SQLite database for offline access.',
                },
                {
                  'title': '5. Data Retention',
                  'content': 'We retain your personal information for as long as your account is active or as needed to provide you services. You can request deletion of your account and associated data at any time.',
                },
                {
                  'title': '6. Your Rights',
                  'content': 'You have the right to:\n• Access your personal information\n• Request correction of inaccurate data\n• Request deletion of your data\n• Opt-out of marketing communications\n• Export your learning data',
                },
                {
                  'title': '7. Children\'s Privacy',
                  'content': 'ACADIA is intended for students of all ages. We do not knowingly collect personal information from children without parental consent. Parents or guardians can review and request deletion of their child\'s information.',
                },
                {
                  'title': '8. Changes to This Policy',
                  'content': 'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the app and updating the "Last updated" date.',
                },
                {
                  'title': '9. Contact Us',
                  'content': 'If you have any questions about this Privacy Policy, please contact us:\n\nEmail: nextgenethiopia@gmail.com\nTelegram: @acadia_support\nPhone: +251 967 870 090',
                },
              ],
            };
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasNetworkError = true;
          _errorMessage = 'Failed to load privacy policy. Please check your connection.';
        });
        _showErrorSnackBar(_errorMessage!);
      }
      debugPrint('Error loading privacy policy: $e');
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
          onPressed: _loadPrivacyPolicy,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Privacy Policy'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading privacy policy...'),
            ],
          ),
        ),
      );
    }

    if (_hasNetworkError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Privacy Policy'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
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
                  _errorMessage ?? 'Unable to load privacy policy',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadPrivacyPolicy,
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

    final List<dynamic> sections = _privacyContent['sections'] ?? [];
    final title = _privacyContent['title']?.toString() ?? 'Privacy Policy';
    final lastUpdated = _privacyContent['last_updated']?.toString() ?? 'May 2026';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1A237E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.privacy_tip, color: Colors.white, size: 36),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last updated: $lastUpdated',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sections
              ...sections.map((section) => _buildSection(
                section['title']?.toString() ?? '',
                section['content']?.toString() ?? '',
              )),

              // Footer
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.security, color: AppColors.primary, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Your privacy matters to us.',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'We are committed to protecting your personal information.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
            ),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}