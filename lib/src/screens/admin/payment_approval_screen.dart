import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class PaymentApprovalScreen extends StatefulWidget {
  const PaymentApprovalScreen({super.key});

  @override
  State<PaymentApprovalScreen> createState() => _PaymentApprovalScreenState();
}

class _PaymentApprovalScreenState extends State<PaymentApprovalScreen> {
  String _statusFilter = 'All'; // All, pending, approved, rejected
  String _packageFilter = 'All';
  String _searchQuery = '';

  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _filteredPayments = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  // Stats
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;
  int _totalCount = 0;
  double _totalRevenue = 0;

  // Status options
  final List<String> _statusOptions = ['All', 'Pending', 'Approved', 'Rejected'];

  // Package options
  final List<String> _packages = [
    'All',
    'Grade 9',
    'Grade 10',
    'Grade 11 Natural Science',
    'Grade 11 Social Science',
    'Grade 12 Natural Science',
    'Grade 12 Social Science',
    'Freshman Sem 1 Natural',
    'Freshman Sem 1 Social',
    'Freshman Sem 2 Pre-Engineering',
    'Freshman Sem 2 Other Natural',
  ];

  // Quick rejection reasons
  final List<String> _quickReasons = [
    'Receipt image unclear',
    'Wrong payment amount',
    'Transaction reference missing',
    'Account number mismatch',
    'Duplicate submission',
    'Suspicious/fraudulent',
    'Payment not received',
    'Wrong payment method used',
  ];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final firebase = FirebaseService();
      final payments = await firebase.getDocuments('payments',
          orderBy: 'submission_date', descending: true);

      double revenue = 0;
      int pending = 0, approved = 0, rejected = 0;

      for (final payment in payments) {
        final status = payment['status']?.toString() ?? '';
        if (status == 'approved') {
          approved++;
          final amount = double.tryParse(payment['amount']?.toString() ?? '0') ?? 0;
          revenue += amount;
        } else if (status == 'pending') {
          pending++;
        } else if (status == 'rejected') {
          rejected++;
        }
      }

      setState(() {
        _payments = payments;
        _filteredPayments = List.from(payments);
        _totalCount = payments.length;
        _pendingCount = pending;
        _approvedCount = approved;
        _rejectedCount = rejected;
        _totalRevenue = revenue;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading payments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading payments'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPayments = _payments.where((payment) {
        // Status filter
        if (_statusFilter != 'All' &&
            payment['status']?.toString().toLowerCase() != _statusFilter.toLowerCase()) {
          return false;
        }

        // Package filter
        if (_packageFilter != 'All') {
          final package = payment['package']?.toString() ?? '';
          if (package != _packageFilter) return false;
        }

        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final name = payment['user_name']?.toString().toLowerCase() ?? '';
          final email = payment['user_email']?.toString().toLowerCase() ?? '';
          final phone = payment['user_phone']?.toString().toLowerCase() ?? '';

          if (!name.contains(query) &&
              !email.contains(query) &&
              !phone.contains(query)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  // ============================================================
  // RECEIPT IMAGE VIEWER
  // ============================================================

  void _viewFullReceipt(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black87,
        child: Stack(
          children: [
            // Full screen image viewer
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading receipt...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load receipt image',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The image may have been deleted or the link is invalid',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Close button
            Positioned(
              top: 40,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            
            // Download button
            Positioned(
              bottom: 40,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () => _saveReceiptToGallery(imageUrl),
                ),
              ),
            ),
            
            // Instructions
            Positioned(
              bottom: 40,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pinch, size: 14, color: Colors.white70),
                    SizedBox(width: 4),
                    Text(
                      'Pinch to zoom • Drag to pan',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveReceiptToGallery(String imageUrl) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading receipt...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        await Gal.putImageBytes(
          response.bodyBytes,
          name: 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receipt saved to gallery!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to download');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // SEND NOTIFICATION TO USER
  // ============================================================

  Future<void> _sendNotificationToUser(
      String userId, String title, String message, String type) async {
    try {
      final firebase = FirebaseService();
      await firebase.addDocument('notifications', {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
        'created_by': 'admin',
      });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  // ============================================================
  // APPROVE PAYMENT
  // ============================================================

  Future<void> _approvePayment(Map<String, dynamic> payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Student', payment['user_name']?.toString() ?? 'Unknown'),
            _buildInfoRow('Email', payment['user_email']?.toString() ?? 'Unknown'),
            _buildInfoRow('Phone', payment['user_phone']?.toString() ?? 'Unknown'),
            _buildInfoRow('Package', payment['package']?.toString() ?? 'Unknown'),
            _buildInfoRow('Amount', '${payment['amount'] ?? '0'} ETB'),
            _buildInfoRow('Method', payment['payment_method']?.toString() ?? 'Unknown'),
            _buildInfoRow('Transaction Ref', payment['transaction_ref']?.toString() ?? 'N/A'),
            const SizedBox(height: 12),
            const Divider(),
            const Text('This will:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('✓ Unlock all subjects for the user'),
            const Text('✓ Set package validity for 1 year from today'),
            const Text('✓ Send approval notification to user'),
            const Text('✓ Update user status to PRO'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('CONFIRM APPROVAL', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final firebase = FirebaseService();
      final now = DateTime.now();
      final validUntil = DateTime(now.year + 1, now.month, now.day);

      // Update payment record
      await firebase.updateDocument('payments', payment['id'], {
        'status': 'approved',
        'approved_at': now.toIso8601String(),
        'approved_by': 'admin',
        'valid_from': now.toIso8601String(),
        'valid_until': validUntil.toIso8601String(),
      });

      // Unlock package for user
      if (payment['user_id'] != null) {
        await firebase.updateDocument('users', payment['user_id'], {
          'is_pro': true,
          'pro_package': payment['package'],
          'pro_valid_from': now.toIso8601String(),
          'pro_valid_until': validUntil.toIso8601String(),
          'package_status': 'active',
        });

        // Send approval notification
        await _sendNotificationToUser(
          payment['user_id'],
          'Payment Approved! 🎉',
          'Your payment for ${payment['package']} has been approved. '
          'All chapters are now unlocked for 1 year. Start studying!',
          'payment',
        );
      }

      await _loadPayments();
      _applyFilters();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment approved! Package unlocked for 1 year.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // ============================================================
  // REJECT PAYMENT
  // ============================================================

  Future<void> _rejectPayment(Map<String, dynamic> payment) async {
    final reasonController = TextEditingController();
    String selectedReason = '';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reject Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Student', payment['user_name']?.toString() ?? 'Unknown'),
                _buildInfoRow('Package', payment['package']?.toString() ?? 'Unknown'),
                _buildInfoRow('Amount', '${payment['amount'] ?? '0'} ETB'),
                const SizedBox(height: 16),
                const Text('Reason for rejection (required):', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter rejection reason...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setDialogState(() => selectedReason = value);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Quick reasons:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickReasons.map((reason) => ActionChip(
                    label: Text(reason, style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      reasonController.text = reason;
                      setDialogState(() => selectedReason = reason);
                    },
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a rejection reason'), backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(context, {'reason': reason});
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('CONFIRM REJECTION', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    setState(() => _isProcessing = true);
    try {
      final firebase = FirebaseService();

      await firebase.updateDocument('payments', payment['id'], {
        'status': 'rejected',
        'rejected_at': DateTime.now().toIso8601String(),
        'rejected_by': 'admin',
        'rejection_reason': result['reason'],
      });

      // Send rejection notification
      if (payment['user_id'] != null) {
        await _sendNotificationToUser(
          payment['user_id'],
          'Payment Rejected ❌',
          'Your payment for ${payment['package']} was rejected.\nReason: ${result['reason']}\n\nPlease submit a new payment with the correct information.',
          'payment',
        );
      }

      await _loadPayments();
      _applyFilters();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment rejected. User has been notified.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // ============================================================
  // VIEW FULL PAYMENT DETAILS
  // ============================================================

  void _viewPaymentDetails(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status header
                Center(
                  child: _buildStatusHeader(payment['status']?.toString() ?? ''),
                ),
                const SizedBox(height: 20),

                // User Information
                const Text('USER INFORMATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const Divider(),
                _buildDetailRow('Full Name', payment['user_name']?.toString() ?? 'N/A'),
                _buildDetailRow('Email', payment['user_email']?.toString() ?? 'N/A'),
                _buildDetailRow('Phone', payment['user_phone']?.toString() ?? 'N/A'),
                _buildDetailRow('User ID', payment['user_id']?.toString() ?? 'N/A'),
                _buildDetailRow('Join Date', _formatDate(payment['user_join_date'])),
                _buildDetailRow('Account Status', payment['is_pro'] == true ? 'PRO' : 'Free'),
                const SizedBox(height: 16),

                // Academic Path
                const Text('ACADEMIC PATH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const Divider(),
                _buildDetailRow('School Level', payment['school_level']?.toString() ?? 'N/A'),
                _buildDetailRow('Grade/Year', payment['grade']?.toString() ?? payment['university_year']?.toString() ?? 'N/A'),
                _buildDetailRow('Stream/Track', payment['stream']?.toString() ?? payment['track']?.toString() ?? 'N/A'),
                const SizedBox(height: 16),

                // Package
                const Text('PACKAGE DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const Divider(),
                _buildDetailRow('Package', payment['package']?.toString() ?? 'N/A'),
                _buildDetailRow('Amount', '${payment['amount'] ?? '0'} ETB'),
                if (payment['valid_from'] != null)
                  _buildDetailRow('Valid From', _formatDateTime(payment['valid_from'])),
                if (payment['valid_until'] != null)
                  _buildDetailRow('Valid Until', _formatDateTime(payment['valid_until'])),
                const SizedBox(height: 16),

                // Payment Information
                const Text('PAYMENT INFORMATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const Divider(),
                _buildDetailRow('Payment Method', payment['payment_method']?.toString() ?? 'N/A'),
                _buildDetailRow('Recipient Account', payment['recipient_account']?.toString() ?? 'N/A'),
                _buildDetailRow('Recipient Name', payment['recipient_name']?.toString() ?? 'N/A'),
                _buildDetailRow('Sender Account', payment['sender_account']?.toString() ?? 'N/A'),
                _buildDetailRow('Transaction Reference', payment['transaction_ref']?.toString() ?? 'N/A'),
                _buildDetailRow('Submission Date', _formatDateTime(payment['submission_date'])),
                if (payment['approved_at'] != null)
                  _buildDetailRow('Approval Date', _formatDateTime(payment['approved_at'])),
                if (payment['rejected_at'] != null) ...[
                  _buildDetailRow('Rejection Date', _formatDateTime(payment['rejected_at'])),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rejection Reason:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(payment['rejection_reason']?.toString() ?? 'No reason provided',
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Receipt Image - FIXED!
                if (payment['receipt_url'] != null && payment['receipt_url'].toString().isNotEmpty) ...[
                  const Text('PAYMENT RECEIPT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                  const Divider(),
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => _viewFullReceipt(payment['receipt_url'].toString()),
                        child: Image.network(
                          payment['receipt_url'].toString(),
                          fit: BoxFit.contain,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Loading receipt...',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Failed to load receipt',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to retry',
                                    style: TextStyle(color: Colors.blue, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => _viewFullReceipt(payment['receipt_url'].toString()),
                        icon: const Icon(Icons.fullscreen, size: 18),
                        label: const Text('View Full Screen'),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: () => _saveReceiptToGallery(payment['receipt_url'].toString()),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Save to Gallery'),
                      ),
                    ],
                  ),
                  // Show Catbox.moe badge
                  if (payment['receipt_url'].toString().contains('catbox.moe'))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.archive, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'Hosted on Catbox.moe',
                            style: TextStyle(color: Colors.grey[500], fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 20),

                // Action buttons for pending payments
                if (payment['status'] == 'pending') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _approvePayment(payment);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('APPROVE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _rejectPayment(payment);
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('REJECT'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _buildStatusHeader(String status) {
    IconData icon;
    Color color;
    String label;

    switch (status) {
      case 'approved':
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'APPROVED';
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = Colors.red;
        label = 'REJECTED';
        break;
      default:
        icon = Icons.access_time;
        color = Colors.orange;
        label = 'PENDING';
    }

    return Column(
      children: [
        Icon(icon, size: 48, color: color),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      DateTime d = date is DateTime ? date : DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (e) {
      return date.toString();
    }
  }

  String _formatDateTime(dynamic date) {
    if (date == null) return 'N/A';
    try {
      DateTime d = date is DateTime ? date : DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return date.toString();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved': return Icons.check_circle;
      case 'pending': return Icons.access_time;
      case 'rejected': return Icons.cancel;
      default: return Icons.help;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Approval'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard('Pending', _pendingCount, Colors.orange),
                const SizedBox(width: 8),
                _buildStatCard('Approved', _approvedCount, Colors.green),
                const SizedBox(width: 8),
                _buildStatCard('Rejected', _rejectedCount, Colors.red),
                const SizedBox(width: 8),
                _buildStatCard('Total', _totalCount, AppColors.primary),
              ],
            ),
          ),

          // Revenue banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Revenue', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        '${_totalRevenue.toStringAsFixed(2)} ETB',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'From ${_approvedCount} approvals',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone number...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v);
                _applyFilters();
              },
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) {
                      setState(() => _statusFilter = v ?? 'All');
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _packageFilter,
                    decoration: InputDecoration(
                      labelText: 'Package',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _packages.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) {
                      setState(() => _packageFilter = v ?? 'All');
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${_filteredPayments.length} payments',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const Spacer(),
                if (_filteredPayments.isNotEmpty)
                  Text(
                    'Total: ${_filteredPayments.fold<double>(0, (sum, p) => sum + (double.tryParse(p['amount']?.toString() ?? '0') ?? 0)).toStringAsFixed(2)} ETB',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),

          // Payment list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPayments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No payments found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Try changing your filters', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredPayments.length,
                        itemBuilder: (context, index) {
                          final payment = _filteredPayments[index];
                          final status = payment['status']?.toString() ?? '';
                          final statusColor = _getStatusColor(status);
                          final statusIcon = _getStatusIcon(status);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () => _viewPaymentDetails(payment),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Status indicator
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(statusIcon, color: statusColor, size: 24),
                                    ),
                                    const SizedBox(width: 12),

                                    // Payment info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            payment['user_name']?.toString() ?? 'Unknown',
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            payment['user_email']?.toString() ?? '',
                                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Icons.phone, size: 12, color: Colors.grey[500]),
                                              const SizedBox(width: 4),
                                              Text(
                                                payment['user_phone']?.toString() ?? '',
                                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  payment['package']?.toString() ?? '',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${payment['amount'] ?? '0'} ETB',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Icons.payment, size: 12, color: Colors.grey[500]),
                                              const SizedBox(width: 4),
                                              Text(
                                                payment['payment_method']?.toString() ?? '',
                                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDate(payment['submission_date']),
                                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Status badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: statusColor.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(count.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}