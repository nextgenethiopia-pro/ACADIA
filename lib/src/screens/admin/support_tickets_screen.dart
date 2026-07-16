import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/constants/colors.dart';

/// Support Tickets Screen
/// 
/// Allows admins to view and manage user support tickets
class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'open', 'in_progress', 'resolved', 'closed'];

  // Mock data for support tickets
  final List<Map<String, dynamic>> _tickets = [
    {
      'id': 'TKT-001',
      'title': 'Unable to download content',
      'user': 'user1@email.com',
      'category': 'Technical',
      'priority': 'high',
      'status': 'open',
      'createdAt': '2024-01-15 10:30',
      'messages': 2,
    },
    {
      'id': 'TKT-002',
      'title': 'Payment not reflected',
      'user': 'user2@email.com',
      'category': 'Payment',
      'priority': 'high',
      'status': 'in_progress',
      'createdAt': '2024-01-14 15:45',
      'messages': 5,
    },
    {
      'id': 'TKT-003',
      'title': 'Content missing in Biology',
      'user': 'user3@email.com',
      'category': 'Content',
      'priority': 'medium',
      'status': 'open',
      'createdAt': '2024-01-13 09:20',
      'messages': 1,
    },
    {
      'id': 'TKT-004',
      'title': 'Account access issue',
      'user': 'user4@email.com',
      'category': 'Account',
      'priority': 'high',
      'status': 'resolved',
      'createdAt': '2024-01-12 14:00',
      'messages': 8,
    },
    {
      'id': 'TKT-005',
      'title': 'Feature request',
      'user': 'user5@email.com',
      'category': 'Feature',
      'priority': 'low',
      'status': 'closed',
      'createdAt': '2024-01-10 11:30',
      'messages': 3,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _createTicket(),
            icon: const Icon(Icons.add),
            tooltip: 'Create Ticket',
          ),
        ],
      ),
      body: Column(
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
                    color: isSelected ? AppColors.primary : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                _buildStatCard('Open', '2', Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard('In Progress', '1', Colors.blue),
                const SizedBox(width: 12),
                _buildStatCard('Resolved', '1', Colors.green),
                const SizedBox(width: 12),
                _buildStatCard('Closed', '1', Colors.grey),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tickets list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tickets.length,
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                return _buildTicketCard(ticket);
              },
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
                      ticket['id'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildPriorityBadge(ticket['priority']),
                  const SizedBox(width: 8),
                  _buildStatusBadge(ticket['status']),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket['title'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    ticket['user'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    ticket['category'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.message, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${ticket['messages']} messages',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket['createdAt'],
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

  void _viewTicket(Map<String, dynamic> ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${ticket['id']}: ${ticket['title']}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('User: ${ticket['user']}'),
              const SizedBox(height: 8),
              Text('Category: ${ticket['category']}'),
              const SizedBox(height: 8),
              Text('Priority: ${ticket['priority']}'),
              const SizedBox(height: 8),
              Text('Status: ${ticket['status']}'),
              const SizedBox(height: 16),
              const Text('Messages:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: ticket['messages'],
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              index % 2 == 0 ? ticket['user'] : 'Admin',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Message content ${index + 1}...'),
                          ],
                        ),
                      ),
                    );
                  },
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
          if (ticket['status'] != 'closed')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateTicketStatus(ticket['id'], 'resolved');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Resolve'),
            ),
        ],
      ),
    );
  }

  void _createTicket() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Support Ticket'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
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

  void _updateTicketStatus(String ticketId, String newStatus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ticket $ticketId marked as $newStatus'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
