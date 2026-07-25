import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/services/firebase_service.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  Map<String, dynamic> _termsContent = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasNetworkError = false;

  @override
  void initState() {
    super.initState();
    _loadTermsOfService();
  }

  Future<void> _loadTermsOfService() async {
    setState(() {
      _isLoading = true;
      _hasNetworkError = false;
      _errorMessage = null;
    });

    try {
      final firebaseService = FirebaseService();
      final settings = await firebaseService.getAppSettings();

      if (settings != null && settings['terms_of_service'] != null) {
        if (mounted) {
          setState(() {
            _termsContent = Map<String, dynamic>.from(settings['terms_of_service']);
            _isLoading = false;
          });
        }
      } else {
        // Default terms of service content
        if (mounted) {
          setState(() {
            _termsContent = {
              'title': 'Terms of Service',
              'last_updated': 'May 2026',
              'sections': [
                {
                  'title': '1. Acceptance of Terms',
                  'content': 'By accessing or using ACADIA ("the App"), you agree to be bound by these Terms of Service. If you disagree with any part of the terms, you may not access the App. These terms constitute a legally binding agreement between you and NextGen Ethiopia PLC.',
                },
                {
                  'title': '2. Use License',
                  'content': 'ACADIA grants you a limited, non-exclusive, non-transferable, revocable license to use the App for personal, educational purposes only. Commercial use of the App or its content is strictly prohibited.',
                },
                {
                  'title': '3. User Accounts',
                  'content': '• You must provide accurate and complete information when creating an account\n• You are responsible for maintaining the confidentiality of your account credentials\n• You must notify us immediately of any unauthorized use of your account\n• You must be at least 13 years old to use this App\n• Parents or guardians are responsible for supervising minors using the App',
                },
                {
                  'title': '4. Academic Path',
                  'content': '• Your selected academic path (grade, stream, university) is permanently locked after registration\n• This choice cannot be changed, so please select carefully during onboarding\n• You can purchase your grade package to unlock all content',
                },
                {
                  'title': '5. Content and Intellectual Property',
                  'content': '• All educational content is for personal learning purposes only\n• You may not copy, distribute, modify, or resell any content from the App\n• All content, including videos, notes, quizzes, and exams, is the property of NextGen Ethiopia PLC\n• Downloading content for offline use is permitted for personal use only',
                },
                {
                  'title': '6. Payments and Refunds',
                  'content': '• Payment fees are charged according to the selected academic path\n• Payments are processed securely through our payment partners (Telebirr, M-PESA, CBE, CBO, Awash Bank)\n• Packages are valid for one year from admin approval date\n• Refund requests will be handled on a case-by-case basis\n• No refunds will be issued after package approval',
                },
                {
                  'title': '7. Prohibited Conduct',
                  'content': 'You agree not to:\n• Share your account credentials with others\n• Attempt to bypass the app\'s security features\n• Use the app for any illegal purpose\n• Harass, abuse, or harm other users\n• Interfere with the app\'s normal functioning',
                },
                {
                  'title': '8. Termination',
                  'content': 'We may terminate or suspend your account immediately, without prior notice, for any violation of these Terms. Upon termination, your right to use the App will cease immediately. You may also delete your account at any time.',
                },
                {
                  'title': '9. Limitation of Liability',
                  'content': 'To the maximum extent permitted by law, ACADIA and its affiliates shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of the App, including loss of data, profits, or learning progress.',
                },
                {
                  'title': '10. Disclaimer of Warranties',
                  'content': 'The App is provided "as is" without warranties of any kind. We do not warrant that the App will be uninterrupted, error-free, or free of viruses or other harmful components.',
                },
                {
                  'title': '11. Changes to Terms',
                  'content': 'We reserve the right to modify these Terms at any time. Changes will be effective immediately upon posting within the App. Your continued use of the App constitutes acceptance of the modified terms.',
                },
                {
                  'title': '12. Governing Law',
                  'content': 'These Terms shall be governed by and construed in accordance with the laws of the Federal Democratic Republic of Ethiopia. Any disputes arising under these Terms shall be subject to the exclusive jurisdiction of Ethiopian courts.',
                },
                {
                  'title': '13. Contact Us',
                  'content': 'For any questions about these Terms of Service, please contact us:\n\nEmail: nextgenethiopia@gmail.com\nTelegram: @acadia_support\nPhone: +251 967 870 090',
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
          _errorMessage = 'Failed to load terms of service. Please check your connection.';
        });
        _showErrorSnackBar(_errorMessage!);
      }
      debugPrint('Error loading terms of service: $e');
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
          onPressed: _loadTermsOfService,
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
          title: const Text('Terms of Service'),
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
              Text('Loading terms of service...'),
            ],
          ),
        ),
      );
    }

    if (_hasNetworkError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Terms of Service'),
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
                  _errorMessage ?? 'Unable to load terms of service',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadTermsOfService,
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

    final List<dynamic> sections = _termsContent['sections'] ?? [];
    final title = _termsContent['title']?.toString() ?? 'Terms of Service';
    final lastUpdated = _termsContent['last_updated']?.toString() ?? 'May 2026';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
                    const Icon(Icons.description, color: Colors.white, size: 36),
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

              // Acceptance Footer
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(((255 * 0.05)).toInt()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withAlpha(((255 * 0.2)).toInt())),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'By using ACADIA, you agree to these terms.',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please read these terms carefully before using the app.',
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