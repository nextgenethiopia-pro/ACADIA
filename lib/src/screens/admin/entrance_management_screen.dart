import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/services/github_content_service.dart';

/// Admin view for entrance exam content.
///
/// Entrance materials (past papers + entrance exam practice sets) are
/// authored as GitHub metadata (`entrance/<stream>.json`), not Firestore
/// documents. This screen is a read-only, offline-first viewer over the
/// cached GitHub catalog with copy-to-clipboard helpers so an admin can
/// quickly find the right metadata file / raw asset URL to edit on GitHub.
class EntranceManagementScreen extends StatefulWidget {
  const EntranceManagementScreen({super.key});

  @override
  State<EntranceManagementScreen> createState() =>
      _EntranceManagementScreenState();
}

class _EntranceManagementScreenState extends State<EntranceManagementScreen> {
  final GithubContentService _github = getIt<GithubContentService>();
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _streams = ['natural_science', 'social_science'];

  bool _isLoading = true;
  bool _isRefreshing = false;
  String _searchQuery = '';
  String _streamFilter = 'All';
  String _typeFilter = 'All';
  String _subjectFilter = 'All';

  Map<String, dynamic>? _entranceIndex;
  final Map<String, Map<String, dynamic>?> _metadataByStream = {};
  List<Map<String, dynamic>> _allItems = [];

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata({bool refresh = false}) async {
    if (!mounted) return;

    setState(() {
      if (refresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
    });

    try {
      final index = await _github.getEntranceIndex();
      final items = <Map<String, dynamic>>[];
      final metadataByStream = <String, Map<String, dynamic>?>{};

      for (final stream in _streams) {
        final metadata = refresh
            ? await _github.refreshEntranceMetadata(stream: stream)
            : await _github.getEntranceMetadata(stream: stream);
        metadataByStream[stream] = metadata;

        final rawItems = metadata?['items'] ??
            metadata?['content'] ??
            metadata?['materials'] ??
            metadata?['papers'] ??
            metadata?['exams'];

        if (rawItems is List) {
          for (final raw in rawItems) {
            if (raw is! Map) continue;
            final item = Map<String, dynamic>.from(raw);
            item['stream'] = stream;
            items.add(item);
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _entranceIndex = index;
        _metadataByStream
          ..clear()
          ..addAll(metadataByStream);
        _allItems = items;

        final subjects = _availableSubjects;
        if (_subjectFilter != 'All' && !subjects.contains(_subjectFilter)) {
          _subjectFilter = 'All';
        }
      });
    } catch (error) {
      debugPrint('Unable to load GitHub entrance metadata: $error');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content will be uploaded soon'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  String _field(Map<String, dynamic> item, List<String> keys,
      [String fallback = '']) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  List<String> get _availableSubjects {
    Iterable<Map<String, dynamic>> items = _allItems;
    if (_streamFilter != 'All') {
      items = items.where((item) => item['stream']?.toString() == _streamFilter);
    }
    if (_typeFilter != 'All') {
      items = items.where(
        (item) => _field(item, ['content_type', 'type']) == _typeFilter,
      );
    }

    final subjects = <String>{};
    for (final item in items) {
      final subject = _field(item, ['subject']);
      if (subject.isNotEmpty) subjects.add(subject);
    }

    final sorted = subjects.toList()..sort();
    return sorted;
  }

  List<Map<String, dynamic>> get _filteredItems {
    Iterable<Map<String, dynamic>> items = _allItems;

    if (_streamFilter != 'All') {
      items = items.where((item) => item['stream']?.toString() == _streamFilter);
    }
    if (_typeFilter != 'All') {
      items = items.where(
        (item) => _field(item, ['content_type', 'type']) == _typeFilter,
      );
    }
    if (_subjectFilter != 'All') {
      items = items.where(
        (item) => _field(item, ['subject']) == _subjectFilter,
      );
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((item) {
        final title = _field(item, ['title', 'name']).toLowerCase();
        final subject = _field(item, ['subject']).toLowerCase();
        final chapter = _field(item, ['chapter', 'unit']).toLowerCase();
        final year = _field(item, ['year']).toLowerCase();
        final grade = _field(item, ['grade']).toLowerCase();
        return title.contains(query) ||
            subject.contains(query) ||
            chapter.contains(query) ||
            year.contains(query) ||
            grade.contains(query);
      });
    }

    final list = items.toList()
      ..sort((a, b) {
        final left = _field(a, ['title', 'name']).toLowerCase();
        final right = _field(b, ['title', 'name']).toLowerCase();
        return left.compareTo(right);
      });

    return list;
  }

  String _streamLabel(String stream) {
    switch (stream) {
      case 'natural_science':
        return 'Natural Science';
      case 'social_science':
        return 'Social Science';
      default:
        return stream.isEmpty ? 'Unknown stream' : stream;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'past_paper':
        return 'Past Paper';
      case 'entrance_exam':
        return 'Entrance Exam';
      default:
        if (type.isEmpty) return 'Unknown';
        return type
            .replaceAll('_', ' ')
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) =>
                '${part.substring(0, 1).toUpperCase()}${part.substring(1)}')
            .join(' ');
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'past_paper':
        return const Color(0xFF2196F3);
      case 'entrance_exam':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'past_paper':
        return Icons.description_outlined;
      case 'entrance_exam':
        return Icons.quiz_outlined;
      default:
        return Icons.menu_book_outlined;
    }
  }

  String _metadataPathForStream(String stream) {
    final entry = _entranceIndex?[stream];
    if (entry is Map) {
      final metadataFile = entry['metadata_file'] ?? entry['metadata'];
      if (metadataFile != null && metadataFile.toString().trim().isNotEmpty) {
        return metadataFile.toString().trim();
      }
    } else if (entry is String && entry.trim().isNotEmpty) {
      return entry.trim();
    }
    return 'entrance/$stream.json';
  }

  String _metadataUrl(String metadataFile) {
    final path = metadataFile.trim().replaceFirst(RegExp(r'^/+'), '');
    return '${_github.baseUrl}/$path';
  }

  Future<void> _copyText(String value, String successMessage) async {
    if (value.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: value));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }

  void _showMaterialDetails(Map<String, dynamic> item) {
    final stream = item['stream']?.toString() ?? '';
    final metadataFile = _metadataPathForStream(stream);
    final metadataUrl = _metadataUrl(metadataFile);
    final downloadUrl = _field(item, ['download_url', 'url', 'pdf_url']);
    final type = _field(item, ['content_type', 'type']);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _field(item, ['title', 'name'], 'Untitled material'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_streamLabel(stream)} • ${_typeLabel(type)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  _DetailRow(
                    label: 'Subject',
                    value: _field(item, ['subject'], 'Not provided'),
                  ),
                  _DetailRow(
                    label: 'Grade',
                    value: _field(item, ['grade'], 'Not provided'),
                  ),
                  _DetailRow(
                    label: 'Year',
                    value: _field(item, ['year'], 'Not provided'),
                  ),
                  _DetailRow(
                    label: 'Chapter',
                    value: _field(item, ['chapter', 'unit'], 'Not provided'),
                  ),
                  _DetailRow(
                    label: 'Total questions',
                    value: _field(item, ['total_questions'], 'Not provided'),
                  ),
                  _DetailRow(
                    label: 'Time limit (minutes)',
                    value:
                        _field(item, ['time_limit_minutes'], 'Not provided'),
                  ),
                  _DetailRow(
                    label: 'Metadata file',
                    value: metadataFile,
                  ),
                  _DetailRow(
                    label: 'Raw metadata URL',
                    value: metadataUrl,
                  ),
                  _DetailRow(
                    label: 'Asset URL',
                    value: downloadUrl.isEmpty
                        ? 'Content will be uploaded soon'
                        : downloadUrl,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () =>
                            _copyText(metadataFile, 'Metadata path copied'),
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copy Path'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _copyText(metadataUrl, 'Raw metadata URL copied'),
                        icon: const Icon(Icons.link),
                        label: const Text('Copy Metadata URL'),
                      ),
                      if (downloadUrl.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () =>
                              _copyText(downloadUrl, 'Asset URL copied'),
                          icon: const Icon(Icons.code),
                          label: const Text('Copy Asset URL'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showWorkflow() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Entrance Content Workflow'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WorkflowStep(
                  number: '1',
                  title: 'Prepare the file',
                  description:
                      'Prepare the past paper PDF or entrance exam JSON with questions.',
                ),
                _WorkflowStep(
                  number: '2',
                  title: 'Upload to GitHub assets',
                  description:
                      'Upload the file to the ACADIA-ASSETS repository under entrance/.',
                ),
                _WorkflowStep(
                  number: '3',
                  title: 'Update stream metadata',
                  description:
                      'Add an item entry (title, subject, grade/year, chapter, url) to entrance/<stream>.json in the metadata repository.',
                ),
                _WorkflowStep(
                  number: '4',
                  title: 'Commit changes',
                  description:
                      'Commit the JSON update and bump version.json so cached catalogs refresh.',
                ),
                _WorkflowStep(
                  number: '5',
                  title: 'Refresh here',
                  description:
                      'Tap Refresh Metadata to confirm the new material is live before announcing it to students.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = _availableSubjects;
    final items = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrance Content (GitHub)'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: _showWorkflow,
            tooltip: 'Upload workflow',
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            onPressed: _isRefreshing ? null : () => _loadMetadata(refresh: true),
            tooltip: 'Refresh metadata',
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadMetadata(refresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _ArchitectureBanner(baseUrl: _github.baseUrl),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by title, subject, chapter, or year',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Stream',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _streamFilter == 'All',
                        onSelected: (_) => setState(() {
                          _streamFilter = 'All';
                          _subjectFilter = 'All';
                        }),
                      ),
                      for (final stream in _streams)
                        ChoiceChip(
                          label: Text(_streamLabel(stream)),
                          selected: _streamFilter == stream,
                          onSelected: (_) => setState(() {
                            _streamFilter = stream;
                            _subjectFilter = 'All';
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Type',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _typeFilter == 'All',
                        onSelected: (_) => setState(() {
                          _typeFilter = 'All';
                          _subjectFilter = 'All';
                        }),
                      ),
                      ChoiceChip(
                        label: const Text('Past Paper'),
                        selected: _typeFilter == 'past_paper',
                        onSelected: (_) => setState(() {
                          _typeFilter = 'past_paper';
                          _subjectFilter = 'All';
                        }),
                      ),
                      ChoiceChip(
                        label: const Text('Entrance Exam'),
                        selected: _typeFilter == 'entrance_exam',
                        onSelected: (_) => setState(() {
                          _typeFilter = 'entrance_exam';
                          _subjectFilter = 'All';
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _subjectFilter,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      prefixIcon: const Icon(Icons.menu_book_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'All',
                        child: Text('All subjects'),
                      ),
                      ...subjects.map(
                        (subject) => DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _subjectFilter = value ?? 'All');
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'Materials',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Spacer(),
                      Chip(
                        avatar: const Icon(Icons.code, size: 18),
                        label: Text('${items.length} materials'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    const _EmptyContent()
                  else
                    ...items.map(
                      (item) => _MaterialMetadataCard(
                        title: _field(item, ['title', 'name'], 'Untitled material'),
                        subject: _field(item, ['subject'], 'Not provided'),
                        streamLabel: _streamLabel(item['stream']?.toString() ?? ''),
                        typeLabel: _typeLabel(_field(item, ['content_type', 'type'])),
                        typeColor: _typeColor(_field(item, ['content_type', 'type'])),
                        typeIcon: _typeIcon(_field(item, ['content_type', 'type'])),
                        grade: _field(item, ['grade']),
                        year: _field(item, ['year']),
                        chapter: _field(item, ['chapter', 'unit']),
                        assetUrl: _field(item, ['download_url', 'url', 'pdf_url']),
                        onTap: () => _showMaterialDetails(item),
                        onCopyAssetUrl: () {
                          final url =
                              _field(item, ['download_url', 'url', 'pdf_url']);
                          _copyText(url, 'Asset URL copied');
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _ArchitectureBanner extends StatelessWidget {
  const _ArchitectureBanner({required this.baseUrl});

  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            scheme.primary.withOpacity(0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school_outlined, color: Colors.white, size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Entrance Content via GitHub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Past papers and entrance exam practice sets are authored as GitHub metadata (entrance/<stream>.json), not Firestore documents.',
            style: TextStyle(color: Colors.white, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              baseUrl,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialMetadataCard extends StatelessWidget {
  const _MaterialMetadataCard({
    required this.title,
    required this.subject,
    required this.streamLabel,
    required this.typeLabel,
    required this.typeColor,
    required this.typeIcon,
    required this.grade,
    required this.year,
    required this.chapter,
    required this.assetUrl,
    required this.onTap,
    required this.onCopyAssetUrl,
  });

  final String title;
  final String subject;
  final String streamLabel;
  final String typeLabel;
  final Color typeColor;
  final IconData typeIcon;
  final String grade;
  final String year;
  final String chapter;
  final String assetUrl;
  final VoidCallback onTap;
  final VoidCallback onCopyAssetUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final subtitleParts = <String>[
      if (subject.isNotEmpty) subject,
      if (grade.isNotEmpty) 'Grade $grade',
      if (year.isNotEmpty) year,
      if (chapter.isNotEmpty) chapter,
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: typeColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitleParts.isEmpty
                          ? streamLabel
                          : '${subtitleParts.join(' • ')} • $streamLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: typeColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            assetUrl.isEmpty
                                ? 'Content will be uploaded soon'
                                : assetUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontFamily: assetUrl.isEmpty ? null : 'monospace',
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (assetUrl.isNotEmpty)
                IconButton(
                  onPressed: onCopyAssetUrl,
                  tooltip: 'Copy asset URL',
                  icon: const Icon(Icons.copy_outlined),
                ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 56),
          SizedBox(height: 16),
          Text(
            'Content will be uploaded soon',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Pull down or use Refresh Metadata to check GitHub again.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(value),
        ],
      ),
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  const _WorkflowStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
