import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/colors.dart';

class GenerationSelectionScreen extends StatefulWidget {
  const GenerationSelectionScreen({super.key});

  @override
  State<GenerationSelectionScreen> createState() => _GenerationSelectionScreenState();
}

class _GenerationSelectionScreenState extends State<GenerationSelectionScreen> {
  String? _selectedGeneration;

  // Ethiopian university generations
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

  final List<Map<String, dynamic>> _generations = [
    {
      'title': '1st Generation',
      'count': '8 universities',
      'universities': _firstGeneration,
      'preview': 'AAU, JU, HU, Haramaya, AASTU, AMU, BDU, MU',
    },
    {
      'title': '2nd Generation',
      'count': '8 universities',
      'universities': _secondGeneration,
      'preview': 'Wollega, Wollo, Dilla, Debre Berhan, Wachamo, Jigjiga, Woldia, Debre Markos',
    },
    {
      'title': '3rd Generation',
      'count': '8 universities',
      'universities': _thirdGeneration,
      'preview': 'Mizan-Tepi, Bule Hora, Wolaita Sodo, Ambo, Assosa, Samara, Dire Dawa, Gambella',
    },
    {
      'title': '4th Generation',
      'count': '8 universities',
      'universities': _fourthGeneration,
      'preview': 'Raya, Debre Tabor, Wachemo, Jinka, Aksum, Werabe, Kebri Dehar, Borana',
    },
    {
      'title': 'Technology Institutes',
      'count': '4 institutes',
      'universities': _technologyInstitutes,
      'preview': 'AASTU, ASTU, JIT, Mekelle Technology University',
    },
  ];

  Future<void> _saveAndContinue() async {
    if (_selectedGeneration == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('generation', _selectedGeneration!);

    // Find the selected generation's universities
    final selected = _generations.firstWhere((g) => g['title'] == _selectedGeneration);
    final universities = selected['universities'] as List<String>;

    if (!mounted) return;
    context.push('/university-selection', extra: {
      'generation': _selectedGeneration,
      'universities': universities,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Select University Generation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          const Text(
            'Choose your university generation',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Generation cards
          ..._generations.map((gen) {
            final isSelected = _selectedGeneration == gen['title'];
            final isTechnology = gen['title'] == 'Technology Institutes';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isSelected ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () => setState(() => _selectedGeneration = gen['title']),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isTechnology
                              ? Colors.teal.withOpacity(0.1)
                              : isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isTechnology ? Icons.precision_manufacturing : Icons.account_balance,
                          color: isTechnology
                              ? Colors.teal
                              : isSelected
                                  ? AppColors.primary
                                  : Colors.grey[600],
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gen['title'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              gen['count'],
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              gen['preview'],
                              style: TextStyle(color: Colors.grey[500], fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Checkmark or chevron
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 20),
                        )
                      else
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedGeneration != null ? _saveAndContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedGeneration != null ? AppColors.primary : Colors.grey[300],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('CONTINUE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}
