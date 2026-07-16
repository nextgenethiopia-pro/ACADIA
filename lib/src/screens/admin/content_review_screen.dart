import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/constants/colors.dart';

/// Content Review Screen
/// 
/// Allows admins to review uploaded content before it's published
class ContentReviewScreen extends StatefulWidget {
  const ContentReviewScreen({super.key});

  @override
  State<ContentReviewScreen> createState() => _ContentReviewScreenState();
}

class _ContentReviewScreenState extends State<ContentReviewScreen> {
  String _selectedFilter = 'all';
  final List<String> _filters = ['all', 'pending', 'approved', 'rejected'];

  // Mock data for pending reviews
  final List<Map<String, dynamic>> _pendingReviews = [
    {
      'id': '1',
      'title': 'Biology Unit 1 Video',
      'subject': 'Biology',
      'type': 'video',
      'uploadedBy': 'teacher1@acadia.edu',
      'uploadedAt': '2024-01-15',
      'status': 'pending',
    },
    {
      'id': '2',
      'title': 'Chemistry Chapter 2 Quiz',
      'subject': 'Chemistry',
      'type': 'quiz',
      'uploadedBy': 'teacher2@acadia.edu',
      'uploadedAt': '2024-01-14',
      'status': 'pending',
    },
    {
      'id': '3',
      'title': 'Mathematics Unit 3 PDF',
      'subject': 'Mathematics',
      'type': 'pdf',
      'uploadedBy': 'teacher3@acadia.edu',
      'uploadedAt': '2024-01-13',
      'status': 'pending',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Review'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
                  label: Text(filter.capitalize()),
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
                _buildStatCard('Pending', '3', Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard('Approved', '45', Colors.green),
                const SizedBox(width: 12),
                _buildStatCard('Rejected', '2', Colors.red),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _pendingReviews.length,
              itemBuilder: (context, index) {
                final review = _pendingReviews[index];
                return _buildReviewCard(review);
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(review['type']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    review['type'].toString().toUpperCase(),
                    style: TextStyle(
                      color: _getTypeColor(review['type']),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    review['subject'],
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review['title'],
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
                  review['uploadedBy'],
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  review['uploadedAt'],
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectContent(review['id']),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveContent(review['id']),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _viewContent(review),
                  icon: const Icon(Icons.visibility),
                  tooltip: 'View Content',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'video':
        return Colors.blue;
      case 'pdf':
        return Colors.red;
      case 'quiz':
        return Colors.orange;
      case 'exam':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _approveContent(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Content'),
        content: const Text('Are you sure you want to approve this content?'),
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
                  content: Text('Content approved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectContent(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Content'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Reason for rejection',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
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
                  content: Text('Content rejected'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _viewContent(Map<String, dynamic> review) {
    // Navigate to content preview
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing ${review['title']}')),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
