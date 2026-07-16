import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/constants/colors.dart';

/// Report Management Screen
/// 
/// Allows admins to view and manage system reports including:
/// - User activity reports
/// - Content performance reports
/// - Payment reports
/// - System health reports
class ReportManagementScreen extends StatefulWidget {
  const ReportManagementScreen({super.key});

  @override
  State<ReportManagementScreen> createState() => _ReportManagementScreenState();
}

class _ReportManagementScreenState extends State<ReportManagementScreen> {
  String _selectedPeriod = '7d';
  final List<String> _periods = ['24h', '7d', '30d', '90d', '1y'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _generateReport(),
            icon: const Icon(Icons.download),
            tooltip: 'Download Report',
          ),
        ],
      ),
      body: Column(
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
                    setState(() => _selectedPeriod = value!);
                  },
                ),
              ],
            ),
          ),

          // Report cards
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildReportCard(
                  'User Activity Report',
                  'Total users, active users, new registrations',
                  Icons.people,
                  Colors.blue,
                  () => _viewReport('user_activity'),
                ),
                const SizedBox(height: 12),
                _buildReportCard(
                  'Content Performance Report',
                  'Most viewed content, completion rates',
                  Icons.bar_chart,
                  Colors.green,
                  () => _viewReport('content_performance'),
                ),
                const SizedBox(height: 12),
                _buildReportCard(
                  'Payment Report',
                  'Revenue, transactions, payment methods',
                  Icons.payments,
                  Colors.orange,
                  () => _viewReport('payment'),
                ),
                const SizedBox(height: 12),
                _buildReportCard(
                  'System Health Report',
                  'Server status, errors, performance metrics',
                  Icons.health_and_safety,
                  Colors.red,
                  () => _viewReport('system_health'),
                ),
                const SizedBox(height: 12),
                _buildReportCard(
                  'Quiz/Exam Results Report',
                  'Average scores, pass rates, subject performance',
                  Icons.quiz,
                  Colors.purple,
                  () => _viewReport('quiz_results'),
                ),
                const SizedBox(height: 12),
                _buildReportCard(
                  'Storage Usage Report',
                  'Downloaded content, storage by subject',
                  Icons.storage,
                  Colors.teal,
                  () => _viewReport('storage_usage'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
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
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
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

  void _viewReport(String reportType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getReportTitle(reportType)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              // Mock report data visualization
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Report Data for $_selectedPeriod',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      const Text('Report visualization would appear here'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadReport(reportType);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Download PDF'),
          ),
        ],
      ),
    );
  }

  String _getReportTitle(String reportType) {
    switch (reportType) {
      case 'user_activity':
        return 'User Activity Report';
      case 'content_performance':
        return 'Content Performance Report';
      case 'payment':
        return 'Payment Report';
      case 'system_health':
        return 'System Health Report';
      case 'quiz_results':
        return 'Quiz/Exam Results Report';
      case 'storage_usage':
        return 'Storage Usage Report';
      default:
        return 'Report';
    }
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating comprehensive report...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _downloadReport(String reportType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${_getReportTitle(reportType)}...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
