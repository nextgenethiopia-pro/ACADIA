import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/constants/colors.dart';

class AdminAppSettingsScreen extends StatefulWidget {
  const AdminAppSettingsScreen({super.key});

  @override
  State<AdminAppSettingsScreen> createState() => _AdminAppSettingsScreenState();
}

class _AdminAppSettingsScreenState extends State<AdminAppSettingsScreen> {
  final Map<String, dynamic> _settings = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedCategory = 'Prices';

  final List<Map<String, String>> _categories = [
    {'id': 'Prices', 'name': 'Package Prices', 'icon': 'attach_money'},
    {'id': 'Quotes', 'name': 'Daily Quote', 'icon': 'format_quote'},
    {'id': 'Tips', 'name': 'Exam Tips', 'icon': 'lightbulb'},
    {'id': 'Welcome', 'name': 'Welcome Screen', 'icon': 'welcome'},
    {'id': 'About', 'name': 'About & Contact', 'icon': 'info'},
    {'id': 'HowTo', 'name': 'How-To Popup', 'icon': 'help'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAllSettings() async {
    setState(() => _isLoading = true);
    try {
      final firebase = FirebaseService();
      final settingsData = await firebase.getAppSettings();

      if (settingsData != null) {
        _settings.clear();
        _settings.addAll(settingsData);
      }

      _initializeDefaultValues();
      _initializeControllers();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading app settings'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _initializeDefaultValues() {
    _settings.putIfAbsent('package_prices', () => {
      'grade_9': 300,
      'grade_10': 350,
      'grade_11_natural': 350,
      'grade_11_social': 350,
      'grade_12_natural': 400,
      'grade_12_social': 400,
      'university_freshman_natural_sem1': 350,
      'university_freshman_social_sem1': 350,
      'university_freshman_pre_eng': 350,
      'university_freshman_other': 300,
    });

    _settings.putIfAbsent('daily_quote', () => {
      'text': 'Education is the most powerful weapon which you can use to change the world.',
      'author': 'Nelson Mandela',
    });

    _settings.putIfAbsent('exam_tips', () => [
      'Start preparing early and create a study schedule',
      'Practice with past papers to understand the format',
      'Focus on weak areas while maintaining strong subjects',
      'Take regular breaks to avoid burnout',
      'Get enough sleep before exam day',
    ]);

    _settings.putIfAbsent('welcome_content', () => {
      'main_title': 'Empowering Ethiopian Students Through Digital Education',
      'subtitle': 'የኢትዮጵያ ተማሪዎችን በዲጂታል ትምህርት ማብቃት',
      'button_text': 'GET STARTED',
    });

    _settings.putIfAbsent('how_to_content', () => {
      'title': 'How to Use ACADIA',
      'button_text': 'GOT IT',
    });

    _settings.putIfAbsent('about_content', () => {
      'developer_name': 'NextGen Ethiopia PLC',
      'developer_email': 'nextgenethiopia@gmail.com',
      'telegram': '@acadia_support',
      'telegram_url': 'https://t.me/acadia_support',
      'website': 'www.acadia.et',
      'website_url': 'https://www.acadia.et',
      'copyright_year': '2026',
    });
  }

  void _initializeControllers() {
    _controllers.clear();

    final prices = _settings['package_prices'] as Map<String, dynamic>? ?? {};
    for (final entry in prices.entries) {
      _controllers[entry.key] = TextEditingController(text: entry.value.toString());
    }

    final quote = _settings['daily_quote'] as Map<String, dynamic>? ?? {};
    _controllers['quote_text'] = TextEditingController(text: quote['text']?.toString() ?? '');
    _controllers['quote_author'] = TextEditingController(text: quote['author']?.toString() ?? '');

    final welcome = _settings['welcome_content'] as Map<String, dynamic>? ?? {};
    _controllers['welcome_title'] = TextEditingController(text: welcome['main_title']?.toString() ?? '');
    _controllers['welcome_subtitle'] = TextEditingController(text: welcome['subtitle']?.toString() ?? '');
    _controllers['welcome_button'] = TextEditingController(text: welcome['button_text']?.toString() ?? '');

    final howTo = _settings['how_to_content'] as Map<String, dynamic>? ?? {};
    _controllers['howto_title'] = TextEditingController(text: howTo['title']?.toString() ?? '');
    _controllers['howto_button'] = TextEditingController(text: howTo['button_text']?.toString() ?? '');

    final about = _settings['about_content'] as Map<String, dynamic>? ?? {};
    _controllers['about_name'] = TextEditingController(text: about['developer_name']?.toString() ?? '');
    _controllers['about_email'] = TextEditingController(text: about['developer_email']?.toString() ?? '');
    _controllers['about_telegram'] = TextEditingController(text: about['telegram']?.toString() ?? '');
    _controllers['about_telegram_url'] = TextEditingController(text: about['telegram_url']?.toString() ?? '');
    _controllers['about_website'] = TextEditingController(text: about['website']?.toString() ?? '');
    _controllers['about_website_url'] = TextEditingController(text: about['website_url']?.toString() ?? '');
    _controllers['about_copyright_year'] = TextEditingController(text: about['copyright_year']?.toString() ?? '');
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final firebase = FirebaseService();
      Map<String, dynamic> updatedSettings = {};

      switch (_selectedCategory) {
        case 'Prices':
          final prices = <String, dynamic>{};
          _controllers.forEach((key, controller) {
            if (key.startsWith('grade_') || key.startsWith('university_')) {
              prices[key] = int.tryParse(controller.text) ?? 300;
            }
          });
          updatedSettings['package_prices'] = prices;
          break;
        case 'Quotes':
          updatedSettings['daily_quote'] = {
            'text': _controllers['quote_text']?.text ?? '',
            'author': _controllers['quote_author']?.text ?? '',
          };
          break;
        case 'Tips':
          updatedSettings['exam_tips'] = _settings['exam_tips'];
          break;
        case 'Welcome':
          updatedSettings['welcome_content'] = {
            'main_title': _controllers['welcome_title']?.text ?? '',
            'subtitle': _controllers['welcome_subtitle']?.text ?? '',
            'button_text': _controllers['welcome_button']?.text ?? '',
          };
          break;
        case 'About':
          updatedSettings['about_content'] = {
            'developer_name': _controllers['about_name']?.text ?? '',
            'developer_email': _controllers['about_email']?.text ?? '',
            'telegram': _controllers['about_telegram']?.text ?? '',
            'telegram_url': _controllers['about_telegram_url']?.text ?? '',
            'website': _controllers['about_website']?.text ?? '',
            'website_url': _controllers['about_website_url']?.text ?? '',
            'copyright_year': _controllers['about_copyright_year']?.text ?? '',
          };
          break;
        case 'HowTo':
          updatedSettings['how_to_content'] = {
            'title': _controllers['howto_title']?.text ?? '',
            'button_text': _controllers['howto_button']?.text ?? '',
          };
          break;
      }

      updatedSettings['last_updated'] = DateTime.now().toIso8601String();
      updatedSettings['updated_by'] = 'admin';

      await firebase.updateAppSettings(updatedSettings);
      await _loadAllSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('App Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [
          if (_isSaving)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else
            TextButton(onPressed: _saveSettings, child: const Text('SAVE', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: Row(children: [
        Container(
          width: 200,
          color: Colors.grey[100],
          child: ListView.builder(
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category['id'];
              return ListTile(
                selected: isSelected,
                selectedTileColor: AppColors.primary.withAlpha((255 * 0.1).toInt()),
                leading: Icon(_getIcon(category['icon']!), color: isSelected ? AppColors.primary : Colors.grey),
                title: Text(category['name']!, style: TextStyle(color: isSelected ? AppColors.primary : null, fontWeight: isSelected ? FontWeight.bold : null)),
                onTap: () => setState(() => _selectedCategory = category['id']!),
              );
            },
          ),
        ),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: _buildCategoryContent())),
      ]),
    );
  }

  Widget _buildCategoryContent() {
    switch (_selectedCategory) {
      case 'Prices': return _buildPricesSection();
      case 'Quotes': return _buildQuotesSection();
      case 'Tips': return _buildTipsSection();
      case 'Welcome': return _buildWelcomeSection();
      case 'About': return _buildAboutSection();
      case 'HowTo': return _buildHowToSection();
      default: return const Center(child: Text('Select a category'));
    }
  }

  Widget _buildPricesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Package Prices', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text('Set prices for each grade package (ETB)', style: TextStyle(color: Colors.grey[600])),
      const SizedBox(height: 24),
      _buildPriceField('Grade 9', 'grade_9'),
      _buildPriceField('Grade 10', 'grade_10'),
      _buildPriceField('Grade 11 Natural', 'grade_11_natural'),
      _buildPriceField('Grade 11 Social', 'grade_11_social'),
      _buildPriceField('Grade 12 Natural', 'grade_12_natural'),
      _buildPriceField('Grade 12 Social', 'grade_12_social'),
      _buildPriceField('Freshman Natural', 'university_freshman_natural_sem1'),
      _buildPriceField('Freshman Social', 'university_freshman_social_sem1'),
      _buildPriceField('Freshman Pre-Eng', 'university_freshman_pre_eng'),
      _buildPriceField('Freshman Other', 'university_freshman_other'),
    ]);
  }

  Widget _buildPriceField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, prefixText: 'ETB ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
      ),
    );
  }

  Widget _buildQuotesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Daily Quote', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text('This quote appears on the home screen', style: TextStyle(color: Colors.grey[600])),
      const SizedBox(height: 24),
      TextFormField(controller: _controllers['quote_text'], maxLines: 3, decoration: InputDecoration(labelText: 'Quote Text', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      TextFormField(controller: _controllers['quote_author'], decoration: InputDecoration(labelText: 'Author', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
    ]);
  }

  Widget _buildTipsSection() {
    final tips = (_settings['exam_tips'] as List?)?.cast<String>() ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Exam Tips', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text('These tips appear in the Entrance Exam tab', style: TextStyle(color: Colors.grey[600])),
      const SizedBox(height: 24),
      ...tips.asMap().entries.map((entry) => _buildTipCard(entry.key, entry.value, tips)),
      const SizedBox(height: 16),
      OutlinedButton.icon(onPressed: () => _addTip(tips), icon: const Icon(Icons.add), label: const Text('Add Tip')),
    ]);
  }

  Widget _buildTipCard(int index, String tip, List<String> tips) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: AppColors.primary.withAlpha((255 * 0.1).toInt()), child: Text('${index + 1}')),
        title: TextFormField(initialValue: tip, onChanged: (value) => _updateTip(index, value, tips), decoration: const InputDecoration(border: InputBorder.none, hintText: 'Enter tip')),
        trailing: IconButton(onPressed: () => _removeTip(index, tips), icon: const Icon(Icons.delete, color: Colors.red)),
      ),
    );
  }

  void _addTip(List<String> tips) { setState(() { tips.add('New exam tip'); _settings['exam_tips'] = tips; }); }
  void _updateTip(int index, String value, List<String> tips) { tips[index] = value; _settings['exam_tips'] = tips; }
  void _removeTip(int index, List<String> tips) { setState(() { tips.removeAt(index); _settings['exam_tips'] = tips; }); }

  Widget _buildWelcomeSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Welcome Screen', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text('Content shown on the welcome/onboarding screen', style: TextStyle(color: Colors.grey[600])),
      const SizedBox(height: 24),
      TextFormField(controller: _controllers['welcome_title'], decoration: InputDecoration(labelText: 'Main Title', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      TextFormField(controller: _controllers['welcome_subtitle'], decoration: InputDecoration(labelText: 'Subtitle (Amharic)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      TextFormField(controller: _controllers['welcome_button'], decoration: InputDecoration(labelText: 'Button Text', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
    ]);
  }

  Widget _buildAboutSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('About & Contact', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text('Developer information and contact details', style: TextStyle(color: Colors.grey[600])),
      const SizedBox(height: 24),
      TextFormField(controller: _controllers['about_name'], decoration: InputDecoration(labelText: 'Developer Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      TextFormField(controller: _controllers['about_email'], decoration: InputDecoration(labelText: 'Contact Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      TextFormField(controller: _controllers['about_telegram'], decoration: InputDecoration(labelText: 'Telegram Handle', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      TextFormField(controller: _controllers['about_telegram_url'], decoration: InputDecoration(labelText: 'Telegram URL', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      TextFormField(controller: _controllers['about_website'], decoration: InputDecoration(labelText: 'Website Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      TextFormField(controller: _controllers['about_website_url'], decoration: InputDecoration(labelText: 'Website URL', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      TextFormField(controller: _controllers['about_copyright_year'], decoration: InputDecoration(labelText: 'Copyright Year', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
    ]);
  }

  Widget _buildHowToSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('How-To Popup', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text('Onboarding tutorial popup content', style: TextStyle(color: Colors.grey[600])),
      const SizedBox(height: 24),
      TextFormField(controller: _controllers['howto_title'], decoration: InputDecoration(labelText: 'Popup Title', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
      const SizedBox(height: 16),
      TextFormField(controller: _controllers['howto_button'], decoration: InputDecoration(labelText: 'Button Text', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
    ]);
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'attach_money': return Icons.attach_money;
      case 'format_quote': return Icons.format_quote;
      case 'lightbulb': return Icons.lightbulb;
      case 'welcome': return Icons.waving_hand;
      case 'info': return Icons.info;
      case 'help': return Icons.help;
      default: return Icons.settings;
    }
  }
}