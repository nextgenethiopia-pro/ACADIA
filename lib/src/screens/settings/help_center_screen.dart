import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:acadia/src/core/constants/colors.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final Map<int, bool> _expandedFaqs = {};

  final List<String> _categories = [
    'All',
    'Account Issues',
    'Content Access',
    'App Performance',
    'Payment Issues',
    'Technical Support',
  ];

  final List<Map<String, dynamic>> _faqItems = [
    // Account Issues
    {
      'question': 'How do I create an account?',
      'answer': 'Tap "Get Started" on the welcome screen, select your academic path (High School or University), choose your grade/stream, then register with your full name, phone number (+251), email, and password.',
      'category': 'Account Issues',
    },
    {
      'question': 'What if I forget my password?',
      'answer': 'On the login screen, click "Forgot Password?" and enter your email address. A password reset link will be sent to your email. Check your spam folder if you don\'t see it.',
      'category': 'Account Issues',
    },
    {
      'question': 'Can I change my academic path after registration?',
      'answer': 'No, your academic path (grade, stream, university) is permanently locked after registration. This choice cannot be changed, so please select carefully during onboarding.',
      'category': 'Account Issues',
    },
    {
      'question': 'How do I verify my email?',
      'answer': 'After registration, a verification email is sent to your email address. Open the email and click the verification link. If you don\'t receive it, check your spam folder or tap "Resend Email" on the verification screen.',
      'category': 'Account Issues',
    },

    // Content Access
    {
      'question': 'How do I purchase a grade package?',
      'answer': 'Go to any locked subject and tap "Unlock", or go to the Subjects tab. Select your package, choose a payment method (Telebirr, M-PESA, CBE, CBO, or Awash Bank), make the payment, upload your receipt screenshot, and enter your transaction details. Your payment will be verified by admin within 24 hours.',
      'category': 'Content Access',
    },
    {
      'question': 'What subjects are included in my package?',
      'answer': 'Natural Science: Mathematics, English, Physics, Chemistry, Biology, IT, Agriculture, and Aptitude. Social Science: Mathematics, English, Geography, History, Economics, Citizenship, IT, and Aptitude. University subjects vary by semester and track.',
      'category': 'Content Access',
    },
    {
      'question': 'How do I access entrance exam preparation?',
      'answer': 'Entrance exam preparation is available for Grade 11 and 12 students who have purchased their grade package. Go to the Entrance tab to access past papers (organized by year from 2014 onwards) and entrance exam practice questions (organized by subject, grade, and chapter).',
      'category': 'Content Access',
    },
    {
      'question': 'Can I download content for offline use?',
      'answer': 'Yes! All content can be downloaded for offline viewing within the app. Videos, short notes (PDF), quizzes, exams, flashcards, and past papers are stored locally. Go to Downloads in Settings to manage your offline content.',
      'category': 'Content Access',
    },
    {
      'question': 'What is free content?',
      'answer': 'Some content is marked as "Free" by admin. Free content is accessible without purchasing a package. Look for the FREE badge on content items.',
      'category': 'Content Access',
    },

    // App Performance
    {
      'question': 'The app is running slowly. What can I do?',
      'answer': 'Try clearing your cache in Settings > Downloads > Clear Cache. Also make sure you have enough storage space on your device. If the issue persists, try restarting the app.',
      'category': 'App Performance',
    },
    {
      'question': 'How do I enable dark mode?',
      'answer': 'Go to Settings > App Settings and toggle the Dark Mode switch. The app will immediately switch to dark theme.',
      'category': 'App Performance',
    },
    {
      'question': 'How do I reduce data usage?',
      'answer': 'Enable Data Saver Mode in Settings > App Settings. This reduces video quality and limits background data usage. Also download content on Wi-Fi for offline use.',
      'category': 'App Performance',
    },

    // Payment Issues
    {
      'question': 'How long does payment verification take?',
      'answer': 'Payments are typically verified within 24 hours. Once approved by admin, you\'ll receive a notification and your package will be unlocked immediately. Check the Notifications tab for updates.',
      'category': 'Payment Issues',
    },
    {
      'question': 'My payment was rejected. What should I do?',
      'answer': 'Check the rejection reason in your payment history. Common reasons include unclear receipt image, missing transaction reference, or wrong amount. Upload a clear screenshot with all transaction details visible and resubmit.',
      'category': 'Payment Issues',
    },
    {
      'question': 'What payment methods are available?',
      'answer': 'We accept Telebirr, M-PESA, Commercial Bank of Ethiopia (CBE), Cooperative Bank of Oromia (CBO), and Awash Bank. All payment details are shown on the payment screen.',
      'category': 'Payment Issues',
    },
    {
      'question': 'How long is my package valid?',
      'answer': 'Each grade package is valid for one year from the date of admin approval. You will be notified before your package expires. After expiry, you need to purchase again.',
      'category': 'Payment Issues',
    },

    // Technical Support
    {
      'question': 'How do I contact support?',
      'answer': 'You can reach us via Telegram @acadia_support, email nextgenethiopia@gmail.com, or call +251 967 870 090. We typically respond within 24 hours during business hours.',
      'category': 'Technical Support',
    },
    {
      'question': 'Is my data secure?',
      'answer': 'Yes, all your personal information and payment data are securely stored. We use Firebase Authentication and secure database rules to protect your data.',
      'category': 'Technical Support',
    },
    {
      'question': 'How do I report a bug?',
      'answer': 'Contact us via email at nextgenethiopia@gmail.com with a description of the issue, your device model, and screenshots if possible. We\'ll work to fix it as soon as possible.',
      'category': 'Technical Support',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredFaqs {
    return _faqItems.where((faq) {
      // Category filter
      if (_selectedCategory != 'All' && faq['category'] != _selectedCategory) {
        return false;
      }
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final question = faq['question'].toString().toLowerCase();
        final answer = faq['answer'].toString().toLowerCase();
        if (!question.contains(query) && !answer.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                  const Icon(Icons.help_outline, color: Colors.white, size: 40),
                  const SizedBox(height: 16),
                  Text(
                    'How can we help you?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search for answers or browse categories below.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withAlpha(((255 * 0.9)).toInt()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search help topics...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 16),

            // FAQ Categories
            Text(
              'Browse by Category',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  final count = _faqItems.where((f) => 
                    (category == 'All' || f['category'] == category)
                  ).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('$category ($count)', style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (v) => setState(() => _selectedCategory = category),
                      selectedColor: AppColors.primary.withAlpha(((255 * 0.2)).toInt()),
                      backgroundColor: Colors.grey[100],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // FAQ Results
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Frequently Asked Questions',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(((255 * 0.1)).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filteredFaqs.length} results',
                    style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_filteredFaqs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('No results found', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Text('Try a different search term', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
              )
            else
              ..._filteredFaqs.map((faq) => _buildFaqItem(faq, theme)),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    Icons.email, 'Email Support',
                    () => _launchEmail('nextgenethiopia@gmail.com'),
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    Icons.telegram, 'Telegram',
                    () => _launchUrl('https://t.me/acadia_support'),
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tutorial Videos
            Text(
              'How to Use ACADIA',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTutorialCard(),
            const SizedBox(height: 24),

            // Contact Section
            Container(
              padding: const EdgeInsets.all(20),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(((255 * 0.1)).toInt()),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.headset_mic, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('Still need help?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Our support team is here to assist you.', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  _buildContactRow(
                    Icons.email, 'Email: nextgenethiopia@gmail.com',
                    () => _launchEmail('nextgenethiopia@gmail.com'),
                  ),
                  const SizedBox(height: 8),
                  _buildContactRow(
                    Icons.telegram, 'Telegram: @acadia_support',
                    () => _launchUrl('https://t.me/acadia_support'),
                  ),
                  const SizedBox(height: 8),
                  _buildContactRow(
                    Icons.phone, 'Phone: +251 967 870 090',
                    () => _launchUrl('tel:+251967870090'),
                  ),
                  const SizedBox(height: 8),
                  _buildContactRow(
                    Icons.access_time, 'Response time: Within 24 hours',
                    () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Version info
            Center(
              child: Text(
                'ACADIA v1.0.0',
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String label, VoidCallback onTap, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(((255 * 0.1)).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(Map<String, dynamic> faq, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(((255 * 0.1)).toInt()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.help_outline, color: AppColors.primary, size: 20),
        ),
        title: Text(
          faq['question'],
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            faq['category'],
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
        ),
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(((255 * 0.03)).toInt()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withAlpha(((255 * 0.1)).toInt())),
            ),
            child: Text(
              faq['answer'],
              style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/tutorial-video'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(((255 * 0.1)).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.play_circle_filled, color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Watch Tutorial Videos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Available in English, Amharic & Afaan Oromoo',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(((255 * 0.1)).toInt()),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13)),
            ),
            if (onTap != () {})
              Icon(Icons.open_in_new, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open link'),
              backgroundColor: Colors.red,
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

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}