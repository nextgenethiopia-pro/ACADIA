import 'package:flutter/material.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/constants/colors.dart';

/// Report Management Screen
///
/// Shows real, Firestore-derived reports for the selected period:
/// - User activity (total / new users)
/// - Content performance (counts by status, downloads)
/// - Payments (counts by status, revenue)
class ReportManagementScreen extends StatefulWidget {
  const ReportManagementScreen({super.key});

  @override
  State<ReportManagementScreen> createState() => _ReportManagementScreenState();
}

class _ReportManagementScreenState extends State<ReportManagementScreen> {
  final FirebaseService _firebase = FirebaseService();

  String _selectedPeriod = '7d';
  final List<String> _periods = ['24h', '7d', '30d', '90d', '1y', 'all'];

  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _content = [];
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _firebase.getDocuments('users'),
      _firebase.getDocuments('content'),
      _firebase.getDocuments('payments'),
    ]);
    if (!mounted) return;
    setState(() {
      _users = results[0];
      _content = results[1];
      _payments = results[2];
      _isLoading = false;
    });
  }

  DateTime? get _periodStart {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case '24h':
        return now.subtract(const Duration(hours: 24));
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
      case '90d':
        return now.subtract(const Duration(days: 90));
      case '1y':
        return now.subtract(const Duration(days: 365));
      default:
        return null; // 'all'
    }
  }

  DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    try {
      return value.toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  bool _inPeriod(dynamic dateValue) {
    final start = _periodStart;
    if (start == null) return true;
    final date = _asDate(dateValue);
    if (date == null) return false;
    return date.isAfter(start);
  }

  int _countInPeriod(List<Map<String, dynamic>> docs, String dateField) =>
      docs.where((d) => _inPeriod(d[dateField])).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Period selector
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Period: ',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedPeriod,
                        items: _periods.map((period) {
                          return DropdownMenuItem(
                            value: period,
                            child: Text(period),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPeriod = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Report cards
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildReportCard(
                          'User Activity Report',
                          '${_users.length} total • ${_countInPeriod(_users, 'created_at')} new in period',
                          Icons.people,
                          Colors.blue,
                          _buildUserActivityMetrics,
                        ),
                        const SizedBox(height: 12),
                        _buildReportCard(
                          'Content Performance Report',
                          '${_content.length} items • ${_totalDownloads()} downloads',
                          Icons.bar_chart,
                          Colors.green,
                          _buildContentMetrics,
                        ),
                        const SizedBox(height: 12),
                        _buildReportCard(
                          'Payment Report',
                          '${_payments.length} payments • ${_revenue().toStringAsFixed(0)} ETB revenue',
                          Icons.payments,
                          Colors.orange,
                          _buildPaymentMetrics,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  int _totalDownloads() => _content.fold<int>(
      0, (sum, c) => sum + ((c['download_count'] as num?)?.toInt() ?? 0));

  double _revenue() => _payments
      .where((p) =>
          (p['status']?.toString() == 'approved') && _inPeriod(p['created_at']))
      .fold<double>(
          0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0));

  List<_Metric> _buildUserActivityMetrics() {
    final premium = _users
        .where((u) =>
            (u['subscription']?.toString().toUpperCase() ?? '') == 'PREMIUM')
        .length;
    return [
      _Metric('Total users', '${_users.length}'),
      _Metric('New in period', '${_countInPeriod(_users, 'created_at')}'),
      _Metric('Premium users', '$premium'),
      _Metric('Free users', '${_users.length - premium}'),
    ];
  }

  List<_Metric> _buildContentMetrics() {
    int byStatus(String s) =>
        _content.where((c) => (c['status']?.toString() ?? 'pending') == s).length;
    return [
      _Metric('Total content', '${_content.length}'),
      _Metric('Approved', '${byStatus('approved')}'),
      _Metric('Pending', '${byStatus('pending')}'),
      _Metric('Rejected', '${byStatus('rejected')}'),
      _Metric('Total downloads', '${_totalDownloads()}'),
    ];
  }

  List<_Metric> _buildPaymentMetrics() {
    int byStatus(String s) => _payments
        .where((p) =>
            (p['status']?.toString() ?? 'pending') == s &&
            _inPeriod(p['created_at']))
        .length;
    final inPeriod = _payments.where((p) => _inPeriod(p['created_at'])).length;
    return [
      _Metric('Payments in period', '$inPeriod'),
      _Metric('Approved', '${byStatus('approved')}'),
      _Metric('Pending', '${byStatus('pending')}'),
      _Metric('Rejected', '${byStatus('rejected')}'),
      _Metric('Revenue (approved)', '${_revenue().toStringAsFixed(0)} ETB'),
    ];
  }

  Widget _buildReportCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    List<_Metric> Function() metricsBuilder,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _viewReport(title, metricsBuilder()),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _viewReport(String title, List<_Metric> metrics) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Period: $_selectedPeriod',
                  style: const TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.w600)),
              const Divider(),
              ...metrics.map((m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(m.label),
                        Text(m.value,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _Metric {
  final String label;
  final String value;
  const _Metric(this.label, this.value);
}
