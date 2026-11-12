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
    {'id': 'General', 'name': 'General Settings', 'icon': 'settings'},
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
    _settings.putIfAbsent('exam_tips', () => [
      'Start your study with the most challenging subjects first.',
      'Take regular breaks during study sessions.',
      'Practice past papers to familiarize yourself with exam patterns.',
      'Stay hydrated and get enough sleep before exams.',
    ]);
  }

  void _initializeControllers() {
    _controllers.clear();

    final prices = _settings['package_prices'] as Map<String, dynamic>? ?? {};
    for (final entry in prices.entries) {
      _controllers[entry.key] = TextEditingController(text: entry.value.toString());
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final firebase = FirebaseService();
      Map<String, dynamic> updatedSettings = {};

      final prices = <String, dynamic>{};
      _controllers.forEach((key, controller) {
        if (key.startsWith('grade_') || key.startsWith('university_')) {
          prices[key] = int.tryParse(controller.text) ?? 300;
        }
      });
      updatedSettings['package_prices'] = prices;

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
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            TextButton(onPressed: _saveSettings, child: const Text('SAVE', style: TextStyle(color: Colors.white))),
        ],
      ),
      body: Row(
        children: [
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
                  selectedTileColor: AppColors.primary.withOpacity(0.1),
                  leading: Icon(_getIcon(category['icon']!), color: isSelected ? AppColors.primary : Colors.grey),
                  title: Text(
                    category['name']!,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                  onTap: () => setState(() => _selectedCategory = category['id']!),
                );
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildCategoryContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent() {
    switch (_selectedCategory) {
      case 'Prices':
        return _buildPricesSection();
      case 'General':
        return _buildGeneralSection();
      default:
        return const Center(child: Text('Select a category'));
    }
  }

  Widget _buildPricesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildGeneralSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('General Settings', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('Configure app-wide settings', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ℹ️ Study Tips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ...(_settings['exam_tips'] as List? ?? []).map((tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tip.toString(), style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Text(
                'Last updated: ${_settings['last_updated']?.toString() ?? 'Never'}',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
              Text(
                'Updated by: ${_settings['updated_by']?.toString() ?? 'N/A'}',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixText: 'ETB ',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.settings;
    }
  }
}