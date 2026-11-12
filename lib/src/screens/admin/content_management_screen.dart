import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/services/github_content_service.dart';

class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  State<ContentManagementScreen> createState() =>
      _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen> {
  final GithubContentService _github = getIt<GithubContentService>();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isRefreshing = false;
  String _searchQuery = '';
  String _academicKey = 'All';

  Map<String, dynamic> _subjectIndex = const {};
  List<Map<String, dynamic>> _subjects = const [];

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
      final index = refresh
          ? await _github.refreshSubjectsIndex()
          : await _github.getSubjectsIndex();

      final normalizedIndex = index ?? const <String, dynamic>{};
      final academicKeys = _extractAcademicKeys(normalizedIndex);

      if (_academicKey != 'All' && !academicKeys.contains(_academicKey)) {
        _academicKey = 'All';
      }

      if (!mounted) return;
      setState(() {
        _subjectIndex = normalizedIndex;
        _subjects = _extractSubjects(normalizedIndex);
      });
    } catch (error) {
      debugPrint('Unable to load GitHub content metadata: $error');

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

  List<String> _extractAcademicKeys(Map<String, dynamic> index) {
    final keys = index.entries
        .where((entry) => entry.value is List)
        .map((entry) => entry.key)
        .toList()
      ..sort();

    return keys;
  }

  List<Map<String, dynamic>> _extractSubjects(
    Map<String, dynamic> index,
  ) {
    final subjects = <Map<String, dynamic>>[];

    for (final entry in index.entries) {
      if (entry.value is! List) continue;
      if (_academicKey != 'All' && entry.key != _academicKey) continue;

      for (final rawSubject in entry.value as List) {
        if (rawSubject is! Map) continue;

        final subject = Map<String, dynamic>.from(rawSubject);
        subject['academic_key'] = entry.key;
        subjects.add(subject);
      }
    }

    subjects.sort((left, right) {
      final leftName = _subjectName(left).toLowerCase();
      final rightName = _subjectName(right).toLowerCase();
      return leftName.compareTo(rightName);
    });

    return subjects;
  }

  List<Map<String, dynamic>> get _filteredSubjects {
    if (_searchQuery.trim().isEmpty) return _subjects;

    final query = _searchQuery.trim().toLowerCase();

    return _subjects.where((subject) {
      return _subjectName(subject).toLowerCase().contains(query) ||
          _subjectCode(subject).toLowerCase().contains(query) ||
          _academicLabel(subject['academic_key']?.toString() ?? '')
              .toLowerCase()
              .contains(query) ||
          (subject['metadata_file']?.toString().toLowerCase() ?? '')
              .contains(query);
    }).toList();
  }

  String _subjectName(Map<String, dynamic> subject) {
    return (subject['name'] ??
            subject['title'] ??
            subject['subject_name'] ??
            subject['id'] ??
            'Untitled subject')
        .toString();
  }

  String _subjectCode(Map<String, dynamic> subject) {
    return (subject['code'] ?? subject['id'] ?? '').toString();
  }

  String _academicLabel(String key) {
    if (key.isEmpty) return 'Unknown path';

    return key
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
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

  void _showSubjectDetails(Map<String, dynamic> subject) {
    final metadataFile = subject['metadata_file']?.toString() ?? '';
    final metadataUrl =
        metadataFile.isEmpty ? '' : _metadataUrl(metadataFile);
    final academicKey = subject['academic_key']?.toString() ?? '';

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
                    _subjectName(subject),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _academicLabel(academicKey),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  _DetailRow(
                    label: 'Subject ID',
                    value: subject['id']?.toString() ?? 'Not provided',
                  ),
                  _DetailRow(
                    label: 'Code',
                    value: _subjectCode(subject).isEmpty
                        ? 'Not provided'
                        : _subjectCode(subject),
                  ),
                  _DetailRow(
                    label: 'Metadata file',
                    value: metadataFile.isEmpty
                        ? 'Content will be uploaded soon'
                        : metadataFile,
                  ),
                  if (metadataUrl.isNotEmpty)
                    _DetailRow(
                      label: 'Raw metadata URL',
                      value: metadataUrl,
                    ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (metadataFile.isNotEmpty)
                        FilledButton.icon(
                          onPressed: () => _copyText(
                            metadataFile,
                            'Metadata path copied',
                          ),
                          icon: const Icon(Icons.copy_outlined),
                          label: const Text('Copy Path'),
                        ),
                      if (metadataUrl.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => _copyText(
                            metadataUrl,
                            'Raw metadata URL copied',
                          ),
                          icon: const Icon(Icons.link),
                          label: const Text('Copy URL'),
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
          title: const Text('GitHub Content Workflow'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WorkflowStep(
                  number: '1',
                  title: 'Upload educational files',
                  description:
                      'Upload PDFs, videos, notes, and thumbnails to the GitHub assets repository.',
                ),
                _WorkflowStep(
                  number: '2',
                  title: 'Update metadata',
                  description:
                      'Edit the relevant subject or entrance JSON file in the metadata repository.',
                ),
                _WorkflowStep(
                  number: '3',
                  title: 'Commit changes',
                  description:
                      'Commit the JSON update and increase version.json when cached catalogs must refresh.',
                ),
                _WorkflowStep(
                  number: '4',
                  title: 'Refresh the app',
                  description:
                      'Use Refresh Metadata here. Users receive the new metadata through the Isar offline cache.',
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
    final academicKeys = _extractAcademicKeys(_subjectIndex);
    final subjects = _filteredSubjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GitHub Content Management'),
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
            onPressed: _isRefreshing
                ? null
                : () => _loadMetadata(refresh: true),
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
                      hintText: 'Search subjects, codes, or metadata paths',
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
                  DropdownButtonFormField<String>(
                    initialValue: _academicKey,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Academic path',
                      prefixIcon: const Icon(Icons.school_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'All',
                        child: Text('All academic paths'),
                      ),
                      ...academicKeys.map(
                        (key) => DropdownMenuItem(
                          value: key,
                          child: Text(_academicLabel(key)),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _academicKey = value ?? 'All';
                        _subjects = _extractSubjects(_subjectIndex);
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'Subjects',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const Spacer(),
                      Chip(
                        avatar: const Icon(Icons.code, size: 18),
                        label: Text('${subjects.length} metadata entries'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (subjects.isEmpty)
                    const _EmptyContent()
                  else
                    ...subjects.map(
                      (subject) => _SubjectMetadataCard(
                        subject: subject,
                        academicLabel: _academicLabel(
                          subject['academic_key']?.toString() ?? '',
                        ),
                        onTap: () => _showSubjectDetails(subject),
                        onCopyPath: () {
                          final path =
                              subject['metadata_file']?.toString() ?? '';
                          _copyText(path, 'Metadata path copied');
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
              Icon(Icons.hub_outlined, color: Colors.white, size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'GitHub Metadata Delivery',
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
            'Subjects, chapters, notes, PDFs, videos, quizzes, and entrance materials are managed through GitHub metadata.',
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

class _SubjectMetadataCard extends StatelessWidget {
  const _SubjectMetadataCard({
    required this.subject,
    required this.academicLabel,
    required this.onTap,
    required this.onCopyPath,
  });

  final Map<String, dynamic> subject;
  final String academicLabel;
  final VoidCallback onTap;
  final VoidCallback onCopyPath;

  @override
  Widget build(BuildContext context) {
    final name = (subject['name'] ??
            subject['title'] ??
            subject['subject_name'] ??
            subject['id'] ??
            'Untitled subject')
        .toString();
    final code = (subject['code'] ?? subject['id'] ?? '').toString();
    final metadataFile = subject['metadata_file']?.toString() ?? '';
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      academicLabel,
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (code.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        code,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      metadataFile.isEmpty
                          ? 'Content will be uploaded soon'
                          : metadataFile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontFamily:
                            metadataFile.isEmpty ? null : 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (metadataFile.isNotEmpty)
                IconButton(
                  onPressed: onCopyPath,
                  tooltip: 'Copy metadata path',
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
