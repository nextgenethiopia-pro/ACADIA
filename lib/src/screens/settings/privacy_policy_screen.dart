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
  static const Map<String, dynamic> _builtInPolicy = {
    'title': 'Privacy Policy',
    'last_updated': 'October 2026',
    'sections': [
      {
        'title': '1. Introduction',
        'content':
            'ACADIA is an educational application operated by NextGen Ethiopia PLC ("we", "our", or "us"). This Privacy Policy explains what information we collect, why we collect it, how it is stored, and the choices available to you when you use ACADIA.',
      },
      {
        'title': '2. Information We Collect',
        'content':
            '• Account information: name, username, email address, and optional phone number.\n'
            '• Academic profile: academic level, grade, stream, university year/semester, track, and department that you select during onboarding.\n'
            '• Learning activity: chapters opened, downloaded content, quiz and exam results, flashcard progress, and study progress stored on your device and, where applicable, in your account.\n'
            '• Payment records: package purchased, payment status, amount, and transaction reference. We do not store full card or mobile-money credentials.\n'
            '• Device and technical data: device type, operating system, app version, and crash diagnostics used to keep the app stable.',
      },
      {
        'title': '3. How We Use Your Information',
        'content':
            'We use your information to create and secure your account, deliver the curriculum and content that matches your academic profile, remember your progress and downloads, process payments and unlock purchased packages, send service notifications you have enabled, respond to support requests, and diagnose and fix technical problems.',
      },
      {
        'title': '4. Storage and Security',
        'content':
            'Account data is stored in Google Firebase Authentication and Cloud Firestore. Content is fetched from the ACADIA content repository. Downloads, highlights, and progress are stored in an on-device Isar database on your phone. Data in transit is protected using HTTPS/TLS. Access to administrative systems is limited to authorized administrators. No method of transmission or storage is completely secure, so absolute security cannot be guaranteed.',
      },
      {
        'title': '5. Third-Party Services',
        'content':
            'ACADIA uses Google Firebase services (Authentication, Cloud Firestore, Cloud Messaging, and Crashlytics) and GitHub-hosted content files. These providers process data on our behalf under their own terms and privacy policies. We do not sell your personal information. We only share information with service providers needed to operate the app, or where required by law.',
      },
      {
        'title': '6. Data Retention',
        'content':
            'We retain account and payment records while your account remains active and as long as needed for legitimate educational, accounting, or legal purposes. Downloaded content, cached data, and local progress remain on your device until you delete them, clear app data, or uninstall the app. You may request deletion of your account and associated account data using the contact details below.',
      },
      {
        'title': '7. Your Rights',
        'content':
            'You may access and correct your profile information in Settings, delete downloaded files in Settings → Downloads, manage notification preferences, and request a copy or deletion of your account data. We will respond to verified requests within a reasonable period. You may also stop all data collection by uninstalling the app, although this does not automatically delete data already stored in your account.',
      },
      {
        'title': '8. Children\'s Privacy',
        'content':
            'ACADIA is used by students, including secondary-school students. Accounts should be created with the knowledge of a parent or guardian where required by local law. We do not knowingly collect more personal information from children than is necessary to provide the educational service. A parent or guardian may contact us to review or request deletion of a child\'s data.',
      },
      {
        'title': '9. Notifications',
        'content':
            'If you enable notifications, ACADIA may send account, payment, content, and study-related messages. Welcome and payment messages are addressed to the specific user account. You can disable notifications in Settings, although important account or payment information may still appear inside the app.',
      },
      {
        'title': '10. Changes to This Policy',
        'content':
            'We may update this Privacy Policy as the app or legal requirements change. The updated version will be published in the app with a new "Last updated" date. Continued use of ACADIA after an update means you accept the revised policy.',
      },
      {
        'title': '11. Contact Us',
        'content':
            'Questions or requests about this Privacy Policy can be sent to:\n\n'
            'NextGen Ethiopia PLC (ACADIA)\n'
            'Email: nextgenethiopia@gmail.com\n'
            'Phone: +251 967 870 090',
      },
      {
        'title': '12. Legal Review Notice',
        'content':
            'This policy describes how the ACADIA application currently handles information. It is pending formal review by qualified legal counsel for the jurisdictions in which ACADIA is offered and should not be treated as a substitute for such review.',
      },
    ],
  };

  Map<String, dynamic> _privacyContent =
      Map<String, dynamic>.from(_builtInPolicy);
  bool _isLoadingRemote = true;
  String? _remoteNotice;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  Future<void> _loadPrivacyPolicy() async {
    setState(() {
      _isLoadingRemote = true;
      _remoteNotice = null;
    });

    try {
      final settings = await FirebaseService()
          .getAppSettings()
          .timeout(const Duration(seconds: 8));
      final remote = settings?['privacy_policy'];
      final remoteSections = remote is Map ? remote['sections'] : null;
      if (remote is Map && remoteSections is List && remoteSections.isNotEmpty) {
        if (mounted) {
          setState(() {
            _privacyContent = Map<String, dynamic>.from(remote);
            _isLoadingRemote = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _isLoadingRemote = false;
          _remoteNotice =
              'The live policy is not published right now. Showing the built-in policy.';
        });
      }
    } catch (e) {
      debugPrint('Error loading remote privacy policy: $e');
      if (mounted) {
        setState(() {
          _isLoadingRemote = false;
          _remoteNotice =
              'The live policy could not be fetched. Showing the built-in policy.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = (_privacyContent['sections'] as List?) ?? const [];
    final title =
        _privacyContent['title']?.toString() ?? 'Privacy Policy';
    final lastUpdated =
        _privacyContent['last_updated']?.toString() ?? 'October 2026';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        elevation: 0,
        bottom: _isLoadingRemote
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPrivacyPolicy,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      const Icon(Icons.privacy_tip,
                          color: Colors.white, size: 36),
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
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (_remoteNotice != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _remoteNotice!,
                            style: const TextStyle(
                                fontSize: 12.5, color: Colors.orange),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadPrivacyPolicy,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ...sections.map((section) {
                  if (section is! Map) return const SizedBox.shrink();
                  return _buildSection(
                    section['title']?.toString() ?? '',
                    section['content']?.toString() ?? '',
                  );
                }),
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
                      const Icon(Icons.security,
                          color: AppColors.primary, size: 32),
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
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12),
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
            decoration: const BoxDecoration(
              border:
                  Border(left: BorderSide(color: AppColors.primary, width: 3)),
            ),
            child: Text(
              title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
                fontSize: 14, height: 1.6, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
