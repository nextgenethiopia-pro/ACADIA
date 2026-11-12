import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/di/injection.dart';
import 'package:acadia/src/core/services/github_content_service.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _dateRange = 'This Month';

  int _totalUsers = 0;
  int _totalContent = 0;
  double _totalRevenue = 0;
  final int _totalUniversities = 44;

  List<Map<String, dynamic>> _revenueTrend = [];
  List<Map<String, dynamic>> _revenueByPackage = [];
  List<Map<String, dynamic>> _usersByPath = [];
  int _userGrowthPercentage = 0;
  int _newUsersThisMonth = 0;
  List<Map<String, dynamic>> _mostViewedContent = [];
  List<Map<String, dynamic>> _contentByType = [];
  List<Map<String, dynamic>> _paymentMethodDistribution = [];

  final List<String> _dateRanges = ['Today', 'This Week', 'This Month', 'This Year'];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (mounted) {
      setState(() {
        if (!_isLoading) _isRefreshing = true;
      });
    }

    try {
      final firebase = FirebaseService();
      final github = getIt<GithubContentService>();
      final users = await firebase.getDocuments('users');
      final payments = await firebase.getDocuments('payments');

      Map<String, dynamic>? subjectsIndex;
      try {
        subjectsIndex = await github.getSubjectsIndex();
      } catch (e) {
        debugPrint('Unable to load GitHub subject metadata: $e');
      }
      final subjectsFromGithub = _flattenSubjectsIndex(subjectsIndex);

      _totalUsers = users.length;
      _totalContent = subjectsFromGithub.length;

      final approvedPayments = payments.where((p) => p['status'] == 'approved').toList();
      _totalRevenue = approvedPayments.fold<double>(0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0));

      _usersByPath = _calculateUsersByPath(users);
      final growthData = _calculateUserGrowth(users);
      _userGrowthPercentage = growthData['percentage'];
      _newUsersThisMonth = growthData['newUsers'];
      _revenueTrend = _calculateRevenueTrend(approvedPayments);
      _revenueByPackage = _calculateRevenueByPackage(approvedPayments);
      _mostViewedContent = _calculateSubjectsByAcademicPath(subjectsFromGithub);
      _contentByType = _calculateContentByType(subjectsFromGithub);
      _paymentMethodDistribution = _calculatePaymentMethodDistribution(payments);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
      debugPrint('Error loading analytics: $e');
    }
  }

  List<Map<String, dynamic>> _calculateUsersByPath(List<Map<String, dynamic>> users) {
    final pathCounts = <String, int>{};
    for (final user in users) {
      final path = _getUserPath(user);
      pathCounts[path] = (pathCounts[path] ?? 0) + 1;
    }
    return pathCounts.entries.map((e) => {'path': e.key, 'count': e.value}).toList()
      ..sort((a, b) => (b['count'] as int) - (a['count'] as int));
  }

  String _getUserPath(Map<String, dynamic> user) {
    final level = user['school_level']?.toString() ?? '';
    if (level == 'high-school') {
      final grade = user['grade']?.toString() ?? '';
      final stream = user['stream']?.toString() ?? '';
      if (grade == '11' || grade == '12') return 'Grade $grade ${stream == 'natural_science' ? 'Natural' : 'Social'}';
      return 'Grade $grade';
    }
    final generation = user['generation']?.toString() ?? '';
    return generation.isNotEmpty ? 'University ($generation)' : 'University';
  }

  Map<String, dynamic> _calculateUserGrowth(List<Map<String, dynamic>> users) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);

    int thisMonthCount = 0;
    int lastMonthCount = 0;

    for (final user in users) {
      try {
        final date = DateTime.parse(user['created_at']?.toString() ?? '');
        if (date.isAfter(thisMonth)) {
          thisMonthCount++;
        } else if (date.isAfter(lastMonth) && date.isBefore(thisMonth)) {
          lastMonthCount++;
        }
      } catch (e) {
        // Ignore invalid dates
      }
    }

    int percentage;
    if (lastMonthCount == 0) {
      percentage = thisMonthCount > 0 ? 100 : 0;
    } else {
      percentage = ((thisMonthCount - lastMonthCount) / lastMonthCount * 100).round();
    }

    return {'percentage': percentage, 'newUsers': thisMonthCount};
  }

  List<Map<String, dynamic>> _calculateRevenueTrend(List<Map<String, dynamic>> payments) {
    final now = DateTime.now();
    final months = <Map<String, dynamic>>[];
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = i == 0 ? now.add(const Duration(days: 1)) : DateTime(now.year, now.month - i + 1, 1);

      double revenue = 0;
      for (final p in payments) {
        try {
          final date = DateTime.parse(p['approved_at']?.toString() ?? p['submission_date']?.toString() ?? p['created_at']?.toString() ?? '');
          if (date.isAfter(month.subtract(const Duration(days: 1))) && date.isBefore(nextMonth)) {
            revenue += (p['amount'] as num?)?.toDouble() ?? 0;
          }
        } catch (e) {
          // Ignore invalid dates
        }
      }
      months.add({'month': monthNames[month.month - 1], 'revenue': revenue});
    }
    return months;
  }

  List<Map<String, dynamic>> _calculateRevenueByPackage(List<Map<String, dynamic>> payments) {
    final packageRevenue = <String, double>{};
    for (final p in payments) {
      final package = p['package']?.toString() ?? 'Unknown';
      packageRevenue[package] = (packageRevenue[package] ?? 0) + ((p['amount'] as num?)?.toDouble() ?? 0);
    }
    return packageRevenue.entries.map((e) => {'package': e.key, 'revenue': e.value}).toList()
      ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
  }

  List<Map<String, dynamic>> _flattenSubjectsIndex(Map<String, dynamic>? index) {
    if (index == null) return const [];
    final subjects = <Map<String, dynamic>>[];
    for (final entry in index.entries) {
      final value = entry.value;
      if (value is! List) continue;
      for (final raw in value) {
        if (raw is! Map) continue;
        final subject = Map<String, dynamic>.from(raw);
        subject['academic_key'] = entry.key;
        subjects.add(subject);
      }
    }
    return subjects;
  }

  String _academicLabel(String key) {
    if (key.isEmpty) return 'Unknown path';
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part.substring(0, 1).toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  List<Map<String, dynamic>> _calculateSubjectsByAcademicPath(List<Map<String, dynamic>> subjects) {
    final pathCounts = <String, int>{};
    for (final subject in subjects) {
      final path = subject['academic_key']?.toString() ?? 'unknown';
      pathCounts[path] = (pathCounts[path] ?? 0) + 1;
    }
    final entries = pathCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => {'title': _academicLabel(e.key), 'count': e.value}).toList();
  }

  List<Map<String, dynamic>> _calculateContentByType(List<Map<String, dynamic>> subjects) {
    final nameCounts = <String, int>{};
    for (final subject in subjects) {
      final name = (subject['name'] ?? subject['title'] ?? subject['id'] ?? 'Unknown').toString();
      nameCounts[name] = (nameCounts[name] ?? 0) + 1;
    }
    return nameCounts.entries.map((e) => {'type': e.key, 'count': e.value}).toList()
      ..sort((a, b) => (b['count'] as int) - (a['count'] as int));
  }

  List<Map<String, dynamic>> _calculatePaymentMethodDistribution(List<Map<String, dynamic>> payments) {
    final methodCounts = <String, int>{};
    for (final p in payments) {
      final method = p['payment_method']?.toString() ?? 'Unknown';
      methodCounts[method] = (methodCounts[method] ?? 0) + 1;
    }
    return methodCounts.entries.map((e) => {'method': e.key, 'count': e.value}).toList()
      ..sort((a, b) => (b['count'] as int) - (a['count'] as int));
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M ETB';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K ETB';
    return '${amount.toInt()} ETB';
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'video': return const Color(0xFFFF9800);
      case 'short_note': return const Color(0xFF2196F3);
      case 'quiz': return const Color(0xFF4CAF50);
      case 'exam': return const Color(0xFF9C27B0);
      case 'flashcard': return const Color(0xFFE91E63);
      case 'past_paper': return const Color(0xFF795548);
      default: return Colors.grey;
    }
  }

  Future<void> _exportFullReportPDF() async {
    try {
      final pdf = pw.Document();

      // Cover Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('ACADIA', style: pw.TextStyle(fontSize: 48, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                pw.Text('Analytics Report', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('Generated: ${DateTime.now().toString().split(' ')[0]}', style: pw.TextStyle(fontSize: 16, color: PdfColors.grey)),
                pw.SizedBox(height: 40),
                pw.Container(width: 200, height: 2, color: PdfColors.blue700),
                pw.SizedBox(height: 20),
                pw.Text('ACADIA - Digital Education Platform', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey)),
                pw.Text('Powered by NextGen Ethiopia', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
              ],
            );
          },
        ),
      );

      // Overview Metrics
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Overview Metrics', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Metric', 'Value'],
                    <String>['Total Registered Users', '$_totalUsers'],
                    <String>['Total Subjects (GitHub)', '$_totalContent'],
                    <String>['Total Revenue', _formatCurrency(_totalRevenue)],
                    <String>['Universities Supported', '$_totalUniversities'],
                    <String>['User Growth Rate', '$_userGrowthPercentage%'],
                    <String>['New Users (This Month)', '$_newUsersThisMonth'],
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.SizedBox(height: 8),
                pw.Text(
                  'ACADIA currently serves $_totalUsers users across $_totalUniversities universities '
                  'with $_totalContent subject materials. Revenue has reached ${_formatCurrency(_totalRevenue)} '
                  'with a user growth rate of $_userGrowthPercentage%.',
                  style: pw.TextStyle(fontSize: 11),
                ),
              ],
            );
          },
        ),
      );

      // Users by Academic Path
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Users by Academic Path', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Academic Path', 'Users', 'Percentage'],
                    ..._usersByPath.map((u) {
                      final count = u['count'] as int;
                      final percentage = _totalUsers > 0 ? (count / _totalUsers * 100).toStringAsFixed(1) : '0.0';
                      return <String>[u['path'].toString(), count.toString(), '$percentage%'];
                    }),
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Total: $_totalUsers users', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            );
          },
        ),
      );

      // Revenue by Package
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Revenue by Package', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Package', 'Revenue (ETB)', 'Percentage'],
                    ..._revenueByPackage.map((r) {
                      final revenue = r['revenue'] as double;
                      final percentage = _totalRevenue > 0 ? (revenue / _totalRevenue * 100).toStringAsFixed(1) : '0.0';
                      return <String>[
                        r['package'].toString(),
                        revenue.toStringAsFixed(2),
                        '$percentage%'
                      ];
                    }),
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Total Revenue: ${_formatCurrency(_totalRevenue)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            );
          },
        ),
      );

      // Payment Method Distribution
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Payment Method Distribution', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Payment Method', 'Count', 'Percentage'],
                    ..._paymentMethodDistribution.map((p) {
                      final count = p['count'] as int;
                      final total = _paymentMethodDistribution.fold<int>(0, (sum, m) => sum + (m['count'] as int));
                      final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
                      return <String>[
                        p['method'].toString(),
                        count.toString(),
                        '$percentage%'
                      ];
                    }),
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            );
          },
        ),
      );

      // Content by Academic Path
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Content by Academic Path', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>['Academic Path', 'Subjects', 'Percentage'],
                    ..._mostViewedContent.map((c) {
                      final count = c['count'] as int;
                      final total = _totalContent;
                      final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
                      return <String>[
                        c['title'].toString(),
                        count.toString(),
                        '$percentage%'
                      ];
                    }),
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Total Subjects: $_totalContent', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            );
          },
        ),
      );

      // Footer
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('ACADIA Analytics Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                pw.SizedBox(height: 16),
                pw.Text('Report generated on ${DateTime.now().toString().split(' ')[0]}', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey)),
                pw.SizedBox(height: 40),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 20),
                pw.Text('ACADIA - Digital Education Platform', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey)),
                pw.Text('Powered by NextGen Ethiopia', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                pw.SizedBox(height: 10),
                pw.Text('© ${DateTime.now().year} NextGen Ethiopia PLC. All rights reserved.', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'acadia_analytics_full_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to ${file.path}'), backgroundColor: Colors.green),
        );
      }

      await Share.shareXFiles([XFile(file.path)], text: 'ACADIA Analytics Full Report (PDF)');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Report',
            onSelected: (value) {
              if (value == 'full') {
                _exportFullReportPDF();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'full',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Export Full Report as PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Range
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _dateRanges.map((range) {
                          final isSelected = _dateRange == range;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(range),
                              selected: isSelected,
                              onSelected: (v) => setState(() => _dateRange = range),
                              selectedColor: AppColors.primary.withOpacity(0.2),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stat Cards
                    Row(
                      children: [
                        _buildStatCard('Total Users', '$_totalUsers', Icons.people, Colors.blue),
                        const SizedBox(width: 8),
                        _buildStatCard('Subjects', '$_totalContent', Icons.description, Colors.green),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatCard('Revenue', _formatCurrency(_totalRevenue), Icons.attach_money, Colors.orange),
                        const SizedBox(width: 8),
                        _buildStatCard('Universities', '$_totalUniversities', Icons.account_balance, Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Revenue Trend                    const Text('Revenue Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(_formatCurrency(_totalRevenue), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(height: 12),
                    _buildBarChart(_revenueTrend.map((r) => _BarData(r['month'] as String, (r['revenue'] as double).toInt())).toList(), Colors.green),
                    const SizedBox(height: 24),

                    // Users by Academic Path
                    const Text('Users by Academic Path', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    ..._usersByPath.take(6).map((u) => _buildHorizontalBar(u['path'] as String, u['count'] as int, _totalUsers, AppColors.primary)),
                    const SizedBox(height: 24),

                    // Revenue by Package
                    const Text('Revenue by Package', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    ..._revenueByPackage.take(6).map((r) => _buildHorizontalBar(r['package'] as String, (r['revenue'] as double).toInt(), _totalRevenue.toInt(), Colors.green)),
                    const SizedBox(height: 24),

                    // Payment Method Distribution
                    const Text('Payment Method Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    ..._paymentMethodDistribution.map((p) {
                      final total = _paymentMethodDistribution.fold<int>(0, (sum, m) => sum + (m['count'] as int));
                      return _buildHorizontalBar(p['method'] as String, p['count'] as int, total, Colors.orange);
                    }),
                    const SizedBox(height: 24),

                    // User Growth
                    const Text('User Growth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_userGrowthPercentage >= 0 ? Colors.green : Colors.red).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$_newUsersThisMonth new users', style: const TextStyle(fontSize: 14)),
                          Row(
                            children: [
                              Icon(
                                _userGrowthPercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                                color: _userGrowthPercentage >= 0 ? Colors.green : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_userGrowthPercentage >= 0 ? '+' : ''}$_userGrowthPercentage%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _userGrowthPercentage >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Content by Academic Path
                    const Text('Content by Academic Path', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    if (_mostViewedContent.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('Content will be uploaded soon', style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ..._mostViewedContent.take(6).map((c) => Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.menu_book_outlined, color: AppColors.primary, size: 18),
                          ),
                          title: Text(c['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          subtitle: const Text('GitHub metadata', style: TextStyle(fontSize: 12)),
                          trailing: Text('${c['count']}', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      )),
                    const SizedBox(height: 24),

                    // Content by Type
                    const Text('Content by Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    if (_contentByType.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('Content will be uploaded soon', style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ..._contentByType.take(10).map((c) => _buildHorizontalBar(
                        c['type'] as String,
                        c['count'] as int,
                        _totalContent,
                        _getTypeColor(c['type'] as String),
                      )),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));

  Widget _buildBarChart(List<_BarData> data, Color color) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxVal = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No data', style: TextStyle(color: Colors.grey))));

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  d.value >= 1000 ? '${(d.value / 1000).toStringAsFixed(0)}K' : '${d.value}',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Container(
                  height: (d.value / maxVal) * 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.5)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(d.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildHorizontalBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              Text('$value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarData {
  final String label;
  final int value;
  _BarData(this.label, this.value);
}