import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/constants/colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _usersByPath = [];
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _pendingPayments = 0;
  int _pendingContent = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
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

      // Calculate stats
      final totalUsers = users.length;
      final totalContent = content.length;
      _pendingContent = content.where((c) => c['status'] == 'pending').length;

      final approvedPayments = payments.where((p) => p['status'] == 'approved').toList();
      final totalRevenue = approvedPayments.fold<int>(0, (sum, p) => sum + ((p['amount'] as num?)?.toInt() ?? 0));

      final uniqueUniversities = <String>{};
      int highSchoolCount = 0;

      final pathCounts = <String, int>{};
      for (var user in users) {
        final level = user['school_level']?.toString() ?? user['academic_level']?.toString() ?? '';
        final grade = user['grade']?.toString() ?? '';
        final stream = user['stream']?.toString() ?? '';

        // Count high school users
        if (level == 'high-school' || level == 'HIGH SCHOOL' || (grade.isNotEmpty && grade != 'freshman')) {
          highSchoolCount++;
        }

        // Count unique universities
        final university = user['university']?.toString();
        if (university != null && university.isNotEmpty) {
          uniqueUniversities.add(university);
        }

        // Users by path
        String pathLabel;
        if (level == 'high-school' || level == 'HIGH SCHOOL') {
          if (grade == '11' || grade == '12') {
            pathLabel = 'G$grade ${stream == 'social' || stream == 'social_science' ? 'Social' : 'Natural'}';
          } else {
            pathLabel = 'Grade $grade';
          }
        } else {
          pathLabel = 'University';
        }
        pathCounts[pathLabel] = (pathCounts[pathLabel] ?? 0) + 1;
      }

      _pendingPayments = payments.where((p) => p['status'] == 'pending').length;

      // Recent activity (combine user registrations and payments)
      final activity = <Map<String, dynamic>>[];
      
      for (var u in users.take(5)) {
        activity.add({
          'title': '${u['full_name'] ?? 'Unknown'} registered',
          'subtitle': 'Grade ${u['grade'] ?? 'University'}',
          'time': u['created_at'],
          'icon': Icons.person_add,
          'color': Colors.blue,
        });
      }
      
      for (var p in payments.take(5)) {
        activity.add({
          'title': 'Payment ${p['status']?.toString().toUpperCase()}',
          'subtitle': '${p['user_name'] ?? 'Unknown'} - ${p['amount'] ?? 0} ETB',
          'time': p['submission_date'] ?? p['created_at'],
          'icon': p['status'] == 'approved' ? Icons.check_circle : Icons.payment,
          'color': p['status'] == 'approved' ? Colors.green : Colors.orange,
        });
      }
      
      activity.sort((a, b) => _parseTimestamp(b['time']).compareTo(_parseTimestamp(a['time'])));

      setState(() {
        _stats = {
          'totalUsers': totalUsers,
          'totalContent': totalContent,
          'totalRevenue': totalRevenue,
          'universities': uniqueUniversities.length,
          'highSchools': highSchoolCount,
        };
        _usersByPath = pathCounts.entries.map((e) => {'path': e.key, 'count': e.value}).toList()
          ..sort((a, b) => (b['count'] as int) - (a['count'] as int));
        _recentActivity = activity.take(8).toList();
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
      debugPrint('Error loading admin dashboard: $e');
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = _parseTimestamp(timestamp);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime(2000);
    if (timestamp is DateTime) return timestamp;
    try {
      return DateTime.parse(timestamp.toString());
    } catch (e) {
      return DateTime(2000);
    }
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M ETB';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K ETB';
    return '$amount ETB';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome
              Row(
                children: [
                  const Text('Welcome, Admin', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'v1.0.0',
                      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Text('Last login: ${_formatTime(DateTime.now())}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 24),

              // 5 Stat Cards
              Row(children: [
                _buildStatCard('Total Users', '${_stats['totalUsers'] ?? 0}', Icons.people, Colors.blue),
                const SizedBox(width: 12),
                _buildStatCard('Total Content', '${_stats['totalContent'] ?? 0}', Icons.description, Colors.green),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _buildStatCard('Revenue', _formatCurrency(_stats['totalRevenue'] as int? ?? 0), Icons.attach_money, Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard('Universities', '${_stats['universities'] ?? 0}', Icons.account_balance, Colors.purple),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _buildStatCard('High Schools', '${_stats['highSchools'] ?? 0}', Icons.school, AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha((255 * 0.1).toInt()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.pending, color: Colors.red, size: 22),
                            const Spacer(),
                            if (_pendingPayments > 0 || _pendingContent > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_pendingPayments + _pendingContent}',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text('Pending', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // Users by Academic Path
              const Text('Users by Academic Path', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ..._usersByPath.take(6).map((u) => _buildHorizontalBar(
                u['path'] as String,
                u['count'] as int,
                _stats['totalUsers'] as int? ?? 1,
                AppColors.primary,
              )),
              const SizedBox(height: 24),

              // Quick Actions
              const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildQuickAction('Content', Icons.folder_open, () => context.push('/admin/content-management'), badge: _pendingContent > 0 ? '$_pendingContent' : null),
                  _buildQuickAction('Users', Icons.people, () => context.push('/admin/user-management')),
                  _buildQuickAction('Payments', Icons.payment, () => context.push('/admin/payment-approval'), badge: _pendingPayments > 0 ? '$_pendingPayments' : null),
                  _buildQuickAction('Notify', Icons.notifications, () => context.push('/admin/create-notification')),
                  _buildQuickAction('Analytics', Icons.analytics, () => context.push('/admin/analytics')),
                  _buildQuickAction('Entrance', Icons.school, () => context.push('/admin/entrance-management')),
                  _buildQuickAction('Settings', Icons.settings, () => context.push('/admin/app-settings')),
                  _buildQuickAction('About', Icons.info, () => context.push('/admin/about-management')),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Activity
              const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              if (_recentActivity.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No recent activity', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ..._recentActivity.map((a) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (a['color'] as Color).withAlpha(((255 * 0.1)).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 20),
                    ),
                    title: Text(a['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text(a['subtitle'] as String, style: const TextStyle(fontSize: 12)),
                    trailing: Text(_formatTime(a['time']), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
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
          color: color.withAlpha(((255 * 0.1)).toInt()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(((255 * 0.2)).toInt())),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const Spacer(),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? value / total : 0.0;
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
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, VoidCallback onTap, {String? badge}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha((255 * 0.1).toInt()),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            if (badge != null)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text(
                    badge,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}