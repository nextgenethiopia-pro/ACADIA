import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/colors.dart';
import '../../widgets/common/gradient_button.dart';

class GenerationSelectionScreen extends StatefulWidget {
  const GenerationSelectionScreen({super.key});

  @override
  State<GenerationSelectionScreen> createState() =>
      _GenerationSelectionScreenState();
}

class _GenerationSelectionScreenState extends State<GenerationSelectionScreen> {
  String? _selectedGeneration;
  bool _isSaving = false;

  static const List<String> _firstGeneration = [
    'AAU - Addis Ababa University',
    'JU - Jimma University',
    'HU - Hawassa University',
    'Haramaya University',
    'AASTU - Addis Ababa Science & Technology University',
    'AMU - Arba Minch University',
    'BDU - Bahir Dar University',
    'MU - Mekelle University',
  ];

  static const List<String> _secondGeneration = [
    'Wollega University',
    'Wollo University',
    'Dilla University',
    'Debre Berhan University',
    'Wachamo University',
    'Jigjiga University',
    'Woldia University',
    'Debre Markos University',
  ];

  static const List<String> _thirdGeneration = [
    'Mizan-Tepi University',
    'Bule Hora University',
    'Wolaita Sodo University',
    'Ambo University',
    'Assosa University',
    'Samara University',
    'Dire Dawa University',
    'Gambella University',
  ];

  static const List<String> _fourthGeneration = [
    'Raya University',
    'Debre Tabor University',
    'Wachemo University',
    'Jinka University',
    'Aksum University',
    'Werabe University',
    'Kebri Dehar University',
    'Borana University',
  ];

  static const List<String> _technologyInstitutes = [
    'AASTU - Addis Ababa Science & Technology University',
    'ASTU - Adama Science & Technology University',
    'JIT - Jimma Institute of Technology',
    'Mekelle Technology University',
  ];

  static const List<Map<String, dynamic>> _generations = [
    {
      'title': '1st Generation',
      'count': '8 universities',
      'universities': _firstGeneration,
      'preview': 'AAU, JU, HU, Haramaya, AASTU, AMU, BDU, MU',
      'icon': Icons.account_balance,
    },
    {
      'title': '2nd Generation',
      'count': '8 universities',
      'universities': _secondGeneration,
      'preview':
          'Wollega, Wollo, Dilla, Debre Berhan, Wachamo, Jigjiga, Woldia, Debre Markos',
      'icon': Icons.account_balance,
    },
    {
      'title': '3rd Generation',
      'count': '8 universities',
      'universities': _thirdGeneration,
      'preview':
          'Mizan-Tepi, Bule Hora, Wolaita Sodo, Ambo, Assosa, Samara, Dire Dawa, Gambella',
      'icon': Icons.account_balance,
    },
    {
      'title': '4th Generation',
      'count': '8 universities',
      'universities': _fourthGeneration,
      'preview':
          'Raya, Debre Tabor, Wachemo, Jinka, Aksum, Werabe, Kebri Dehar, Borana',
      'icon': Icons.account_balance,
    },
    {
      'title': 'Technology Institutes',
      'count': '4 institutes',
      'universities': _technologyInstitutes,
      'preview': 'AASTU, ASTU, JIT, Mekelle Technology University',
      'icon': Icons.precision_manufacturing,
    },
  ];

  Future<void> _saveAndContinue() async {
    if (_selectedGeneration == null || _isSaving) return;

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_generation', _selectedGeneration!);
    await prefs.setString('generation', _selectedGeneration!);

    final selected = _generations.firstWhere(
      (generation) => generation['title'] == _selectedGeneration,
    );
    final universities =
        List<String>.from(selected['universities'] as List<String>);

    if (!mounted) return;

    context.push(
      '/university-selection',
      extra: {
        'generation': _selectedGeneration,
        'universities': universities,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select University Generation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSaving ? null : () => context.pop(),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your university generation to narrow down your institution list.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(((255 * 0.75)).toInt()),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(((255 * 0.06)).toInt()),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(((255 * 0.12)).toInt()),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This helps ACADIA show the correct university options for your registration path.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _generations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final generation = _generations[index];
                    final title = generation['title'] as String;
                    final count = generation['count'] as String;
                    final preview = generation['preview'] as String;
                    final icon = generation['icon'] as IconData;
                    final isSelected = _selectedGeneration == title;

                    return _buildGenerationCard(
                      title: title,
                      count: count,
                      preview: preview,
                      icon: icon,
                      isSelected: isSelected,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                text: 'CONTINUE',
                onPressed: _selectedGeneration != null && !_isSaving
                    ? _saveAndContinue
                    : () {},
                isDisabled: _selectedGeneration == null || _isSaving,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenerationCard({
    required String title,
    required String count,
    required String preview,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap:
          _isSaving ? null : () => setState(() => _selectedGeneration = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withAlpha(((255 * 0.06)).toInt()) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2.2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withAlpha(((255 * 0.12)).toInt())
                  : Colors.black.withAlpha(((255 * 0.04)).toInt()),
              blurRadius: isSelected ? 18 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((255 * (isSelected ? 0.16 : 0.08)).toInt()),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color:
                                isSelected ? AppColors.primary : Colors.black87,
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isSelected ? 1 : 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    preview,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
