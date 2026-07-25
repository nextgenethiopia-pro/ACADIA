import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  // Statistics
  int _totalPayments = 0;
  double _totalSpent = 0;
  int _approvedCount = 0;
  int _pendingCount = 0;
  int _rejectedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    if (mounted) {
      setState(() {
        if (!_isLoading) _isRefreshing = true;
      });
    }
    
    try {
      final firebaseService = FirebaseService();
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        final payments = await firebaseService.getUserPayments();
        
        // Calculate statistics
        int approved = 0, pending = 0, rejected = 0;
        double totalSpent = 0;
        
        for (final payment in payments) {
          final status = payment['status']?.toString() ?? '';
          final amount = double.tryParse(payment['amount']?.toString() ?? '0') ?? 0;
          
          if (status == 'approved') {
            approved++;
            totalSpent += amount;
          } else if (status == 'pending') {
            pending++;
          } else if (status == 'rejected') {
            rejected++;
          }
        }
        
        if (mounted) {
          setState(() {
            _payments = payments;
            _approvedCount = approved;
            _pendingCount = pending;
            _rejectedCount = rejected;
            _totalSpent = totalSpent;
            _totalPayments = payments.length;
            _isLoading = false;
            _isRefreshing = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isRefreshing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
      debugPrint('Error loading payments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading payment history'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredPayments {
    var filtered = _payments;

    // Status filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((p) => p['status'] == _selectedFilter.toLowerCase()).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        final package = (p['package_name'] ?? p['package'] ?? '').toString().toLowerCase();
        final date = _formatDate(p['created_at'] ?? p['date']);
        final amount = p['amount']?.toString() ?? '';
        return package.contains(query) || date.contains(query) || amount.contains(query);
      }).toList();
    }

    return filtered;
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved': return Icons.check_circle;
      case 'pending': return Icons.access_time;
      case 'rejected': return Icons.cancel;
      default: return Icons.help;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      DateTime date = timestamp is DateTime ? timestamp : DateTime.parse(timestamp.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      DateTime date = timestamp is DateTime ? timestamp : DateTime.parse(timestamp.toString());
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  void _viewReceipt(String? receiptUrl) async {
    if (receiptUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No receipt available'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final uri = Uri.parse(receiptUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open receipt'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment History'),
          leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          if (_payments.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatCard('Total', '$_totalPayments', 'payments', AppColors.primary),
                  const SizedBox(width: 8),
                  _buildStatCard('Spent', '${_totalSpent.toStringAsFixed(0)}', 'ETB', Colors.green),
                  const SizedBox(width: 8),
                  _buildStatCard('Approved', '$_approvedCount', '', Colors.green),
                  const SizedBox(width: 8),
                  _buildStatCard('Pending', '$_pendingCount', '', Colors.orange),
                ],
              ),
            ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All', _payments.length),
                _buildFilterChip('Pending', _pendingCount),
                _buildFilterChip('Approved', _approvedCount),
                _buildFilterChip('Rejected', _rejectedCount),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by package, date, or amount...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Payment List
          Expanded(
            child: _filteredPayments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('No payments found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(
                          _payments.isEmpty 
                              ? 'Your payment history will appear here' 
                              : 'No matching payments',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                        if (_payments.isEmpty)
                          const SizedBox(height: 16),
                        if (_payments.isEmpty)
                          ElevatedButton.icon(
                            onPressed: () => context.push('/payment'),
                            icon: const Icon(Icons.payment),
                            label: const Text('Make a Payment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadPayments,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredPayments.length,
                      itemBuilder: (context, index) {
                        final payment = _filteredPayments[index];
                        final status = payment['status']?.toString() ?? 'pending';
                        final statusColor = _getStatusColor(status);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Status icon
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: statusColor.withAlpha(((255 * 0.1)).toInt()),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(_getStatusIcon(status), color: statusColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            payment['package_name'] ?? payment['package'] ?? 'Package',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatDateTime(payment['created_at'] ?? payment['date']),
                                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${payment['amount'] ?? 0} ETB',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: statusColor.withAlpha(((255 * 0.1)).toInt()),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Payment method
                                Row(
                                  children: [
                                    Icon(Icons.payment, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 6),
                                    Text(
                                      payment['payment_method']?.toString() ?? 'Unknown method',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                    const Spacer(),
                                    if (payment['receipt_url'] != null)
                                      TextButton.icon(
                                        onPressed: () => _viewReceipt(payment['receipt_url']),
                                        icon: const Icon(Icons.receipt, size: 16),
                                        label: const Text('View Receipt', style: TextStyle(fontSize: 12)),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 30),
                                        ),
                                      ),
                                  ],
                                ),
                                
                                // Transaction reference
                                if (payment['transaction_ref'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.receipt, size: 12, color: Colors.grey[400]),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Ref: ${payment['transaction_ref']}',
                                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                // Rejection reason
                                if (status == 'rejected' && payment['rejection_reason'] != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withAlpha(((255 * 0.05)).toInt()),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red.withAlpha(((255 * 0.15)).toInt())),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.red[400], size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Reason: ${payment['rejection_reason']}',
                                            style: TextStyle(color: Colors.red[700], fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String sublabel, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(((255 * 0.1)).toInt()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
            ),
            if (sublabel.isNotEmpty)
              Text(
                sublabel,
                style: TextStyle(fontSize: 9, color: color.withAlpha(((255 * 0.7)).toInt())),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label ($count)', style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedFilter = label),
        selectedColor: AppColors.primary.withAlpha(((255 * 0.2)).toInt()),
        backgroundColor: Colors.grey[100],
      ),
    );
  }
}