import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
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
      final users = await firebase.getDocuments('users');
      final content = await firebase.getDocuments('content');
      final payments = await firebase.getDocuments('payments');

      _totalUsers = users.length;
      _totalContent = content.length;

      final approvedPayments = payments.where((p) => p['status'] == 'approved').toList();
      _totalRevenue = approvedPayments.fold<double>(0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0));

      _usersByPath = _calculateUsersByPath(users);
      final growthData = _calculateUserGrowth(users);
      _userGrowthPercentage = growthData['percentage'];
      _newUsersThisMonth = growthData['newUsers'];
      _revenueTrend = _calculateRevenueTrend(approvedPayments);
      _revenueByPackage = _calculateRevenueByPackage(approvedPayments);
      _mostViewedContent = _calculateMostViewedContent(content);
      _contentByType = _calculateContentByType(content);
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

  List<Map<String, dynamic>> _calculateMostViewedContent(List<Map<String, dynamic>> content) {
    final sorted = List<Map<String, dynamic>>.from(content)
      ..sort((a, b) {
        final aVal = a['download_count'] is int ? a['download_count'] as int : int.tryParse(a['download_count']?.toString() ?? '0') ?? 0;
        final bVal = b['download_count'] is int ? b['download_count'] as int : int.tryParse(b['download_count']?.toString() ?? '0') ?? 0;
        return bVal - aVal;
      });
    return sorted.where((c) => (c['download_count'] as int? ?? 0) > 0).take(10).map((c) => ({
      'title': c['title']?.toString() ?? 'Untitled',
      'type': c['content_type']?.toString() ?? 'unknown',
      'subject': c['subject']?.toString() ?? '',
      'downloads': c['download_count']?.toString() ?? '0'
    })).toList();
  }

  List<Map<String, dynamic>> _calculateContentByType(List<Map<String, dynamic>> content) {
    final typeCounts = <String, int>{};
    for (final c in content) {
      final type = c['content_type']?.toString() ?? 'unknown';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }
    return typeCounts.entries.map((e) => {'type': e.key, 'count': e.value}).toList()
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

  Future<void> _exportCSV() async {
    try {
      final csvData = <List<String>>[];
      csvData.add(['Metric', 'Value']);
      csvData.add(['Total Users', _totalUsers.toString()]);
      csvData.add(['Total Content', _totalContent.toString()]);
      csvData.add(['Total Revenue', _totalRevenue.toString()]);
      csvData.add(['Total Universities', _totalUniversities.toString()]);
      csvData.add(['User Growth', '$_userGrowthPercentage%']);
      csvData.add(['New Users This Month', _newUsersThisMonth.toString()]);
      csvData.add(['']);
      csvData.add(['Revenue by Package']);
      csvData.add(['Package', 'Revenue']);
      for (final p in _revenueByPackage) {
        csvData.add([p['package'].toString(), p['revenue'].toString()]);
      }
      
      final csv = const ListToCsvConverter().convert(csvData);
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/analytics_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'ACADIA Analytics Report');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
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
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onSelected: (value) {
              if (value == 'csv') _exportCSV();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'csv', child: Row(
                children: [Icon(Icons.table_chart, size: 18), SizedBox(width: 8), Text('Export as CSV')],
              )),
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Date Range
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: _dateRanges.map((range) {
                      final isSelected = _dateRange == range;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(range),
                          selected: isSelected,
                          onSelected: (v) => setState(() => _dateRange = range),
                          selectedColor: AppColors.primary.withAlpha(((255 * 0.2)).toInt()),
                        ),
                      );
                    }).toList()),
                  ),
                  const SizedBox(height: 20),

                  // Stat Cards
                  Row(children: [
                    _buildStatCard('Total Users', '$_totalUsers', Icons.people, Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatCard('Content', '$_totalContent', Icons.description, Colors.green),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    _buildStatCard('Revenue', _formatCurrency(_totalRevenue), Icons.attach_money, Colors.orange),
                    const SizedBox(width: 8),
                    _buildStatCard('Universities', '$_totalUniversities', Icons.account_balance, Colors.purple),
                  ]),
                  const SizedBox(height: 24),

                  // Revenue Trend
                  _buildSectionTitle('Revenue Trend'),
                  const SizedBox(height: 4),
                  Text(_formatCurrency(_totalRevenue), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 12),
                  _buildBarChart(_revenueTrend.map((r) => _BarData(r['month'] as String, (r['revenue'] as double).toInt())).toList(), Colors.green),
                  const SizedBox(height: 24),

                  // Users by Academic Path
                  _buildSectionTitle('Users by Academic Path'),
                  const SizedBox(height: 12),
                  ..._usersByPath.take(6).map((u) => _buildHorizontalBar(u['path'] as String, u['count'] as int, _totalUsers, AppColors.primary)),
                  const SizedBox(height: 24),

                  // Revenue by Package
                  _buildSectionTitle('Revenue by Package'),
                  const SizedBox(height: 12),
                  ..._revenueByPackage.take(6).map((r) => _buildHorizontalBar(r['package'] as String, (r['revenue'] as double).toInt(), _totalRevenue.toInt(), Colors.green)),
                  const SizedBox(height: 24),

                  // Payment Method Distribution
                  _buildSectionTitle('Payment Method Distribution'),
                  const SizedBox(height: 12),
                  ..._paymentMethodDistribution.map((p) {
                    final total = _paymentMethodDistribution.fold<int>(0, (sum, m) => sum + (m['count'] as int));
                    return _buildHorizontalBar(p['method'] as String, p['count'] as int, total, Colors.orange);
                  }),
                  const SizedBox(height: 24),

                  // User Growth
                  _buildSectionTitle('User Growth'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_userGrowthPercentage >= 0 ? Colors.green : Colors.red).withAlpha(((255 * 0.1)).toInt()),
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

                  // Most Viewed Content
                  _buildSectionTitle('Most Viewed Content'),
                  const SizedBox(height: 12),
                  if (_mostViewedContent.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No data available', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    ..._mostViewedContent.take(5).map((c) => Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _getTypeColor(c['type'] as String).withAlpha(((255 * 0.1)).toInt()),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.trending_up, color: _getTypeColor(c['type'] as String), size: 18),
                        ),
                        title: Text(c['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        subtitle: Text('${c['subject']} • ${(c['type'] as String).replaceAll('_', ' ')}', style: const TextStyle(fontSize: 12)),
                        trailing: Text('${c['downloads']}', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    )),
                  const SizedBox(height: 24),

                  // Content by Type
                  _buildSectionTitle('Content by Type'),
                  const SizedBox(height: 12),
                  ..._contentByType.map((c) => _buildHorizontalBar(
                    (c['type'] as String).replaceAll('_', ' ').toUpperCase(),
                    c['count'] as int,
                    _totalContent,
                    _getTypeColor(c['type'] as String),
                  )),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(((255 * 0.1)).toInt()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(((255 * 0.2)).toInt())),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      colors: [color, color.withAlpha(((255 * 0.5)).toInt())],
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