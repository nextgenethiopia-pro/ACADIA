import 'package:flutter/material.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/constants/colors.dart';

/// Support Tickets Screen
///
/// Lets admins view and manage user support tickets stored in the Firestore
/// `support_tickets` collection.
class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  final FirebaseService _firebase = FirebaseService();

  String _selectedFilter = 'all';
  final List<String> _filters = [
    'all',
    'open',
    'in_progress',
    'resolved',
    'closed'
  ];

  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    final tickets = await _firebase.getDocuments(
      'support_tickets',
      orderBy: 'created_at',
      descending: true,
    );
    if (!mounted) return;
    setState(() {
      _tickets = tickets;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredTickets {
    if (_selectedFilter == 'all') return _tickets;
    return _tickets
        .where((t) => (t['status']?.toString() ?? 'open') == _selectedFilter)
        .toList();
  }

  int _countByStatus(String status) =>
      _tickets.where((t) => (t['status']?.toString() ?? 'open') == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadTickets,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _createTicket,
            icon: const Icon(Icons.add),
            tooltip: 'Create Ticket',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return FilterChip(
                        label: Text(_formatFilter(filter)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedFilter = filter);
                        },
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color:
                              isSelected ? AppColors.primary : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildStatCard(
                          'Open', '${_countByStatus('open')}', Colors.orange),
                      const SizedBox(width: 12),
                      _buildStatCard('In Progress',
                          '${_countByStatus('in_progress')}', Colors.blue),
                      const SizedBox(width: 12),
                      _buildStatCard('Resolved',
                          '${_countByStatus('resolved')}', Colors.green),
                      const SizedBox(width: 12),
                      _buildStatCard('Closed',
                          '${_countByStatus('closed')}', Colors.grey),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tickets list
                Expanded(
                  child: _filteredTickets.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _loadTickets,
                          child: ListView(
                            children: [
                              const SizedBox(height: 80),
                              Icon(Icons.support_agent,
                                  size: 56, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Center(
                                child: Text('No support tickets',
                                    style:
                                        TextStyle(color: Colors.grey[500])),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTickets,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredTickets.length,
                            itemBuilder: (context, index) {
                              return _buildTicketCard(_filteredTickets[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final id = ticket['id']?.toString() ?? '';
    final title = ticket['title']?.toString() ?? 'Untitled';
    final user = ticket['user_email']?.toString() ??
        ticket['user']?.toString() ??
        'unknown';
    final category = ticket['category']?.toString() ?? 'General';
    final priority = ticket['priority']?.toString() ?? 'medium';
    final status = ticket['status']?.toString() ?? 'open';
    final createdAt = _formatDate(ticket['created_at']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _viewTicket(ticket),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      id.length > 8 ? 'TKT-${id.substring(0, 8)}' : 'TKT-$id',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildPriorityBadge(priority),
                  const SizedBox(width: 8),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      user,
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    category,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                createdAt,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    switch (priority) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'open':
        color = Colors.orange;
        break;
      case 'in_progress':
        color = Colors.blue;
        break;
      case 'resolved':
        color = Colors.green;
        break;
      case 'closed':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _formatFilter(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatFilter(String filter) {
    return filter.split('_').map((word) => word.capitalize()).join(' ');
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    DateTime? parsed;
    if (value is String) {
      parsed = DateTime.tryParse(value);
    } else {
      // Firestore Timestamp exposes toDate() via dynamic; guard with try.
      try {
        parsed = value.toDate() as DateTime;
      } catch (_) {
        parsed = null;
      }
    }
    if (parsed == null) return value.toString();
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} '
        '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  void _viewTicket(Map<String, dynamic> ticket) {
    final status = ticket['status']?.toString() ?? 'open';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(ticket['title']?.toString() ?? 'Ticket'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('User',
                  ticket['user_email']?.toString() ?? ticket['user']?.toString() ?? '—'),
              _detailRow('Category', ticket['category']?.toString() ?? '—'),
              _detailRow('Priority', ticket['priority']?.toString() ?? '—'),
              _detailRow('Status', _formatFilter(status)),
              const SizedBox(height: 12),
              const Text('Description:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(ticket['description']?.toString() ?? 'No description provided.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          if (status != 'in_progress' && status != 'closed' && status != 'resolved')
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _updateTicketStatus(ticket, 'in_progress');
              },
              child: const Text('Start'),
            ),
          if (status != 'closed')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _updateTicketStatus(
                    ticket, status == 'resolved' ? 'closed' : 'resolved');
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      status == 'resolved' ? Colors.grey : Colors.green),
              child: Text(status == 'resolved' ? 'Close' : 'Resolve'),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  void _createTicket() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final userController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Support Ticket'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: userController,
                decoration: const InputDecoration(
                  labelText: 'User email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(dialogContext);
              await _firebase.addDocument('support_tickets', {
                'title': title,
                'description': descController.text.trim(),
                'user_email': userController.text.trim(),
                'category': 'General',
                'priority': 'medium',
                'status': 'open',
              });
              await _loadTickets();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support ticket created'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTicketStatus(
      Map<String, dynamic> ticket, String newStatus) async {
    final id = ticket['id']?.toString();
    if (id == null) return;
    try {
      await _firebase.updateDocument('support_tickets', id, {'status': newStatus});
      if (!mounted) return;
      setState(() => ticket['status'] = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket marked as ${_formatFilter(newStatus)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
