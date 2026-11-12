import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/services/package_service.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:acadia/src/models/user_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _subscriptionFilter = 'All';
  String _pathFilter = 'All';

  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _exportingAll = false;

  int _totalUsers = 0;
  int _activeUsers = 0;
  int _proUsers = 0;
  int _freeUsers = 0;
  int _bannedUsers = 0;
  List<String> _adminEmails = [];

  final List<String> _statusOptions = ['All', 'Active', 'Banned'];
  final List<String> _subscriptionOptions = ['All', 'Pro', 'Free'];

  final List<_PathFilterOption> _pathOptions = [
    _PathFilterOption('All', 'All Paths'),
    _PathFilterOption('grade_9', 'Grade 9'),
    _PathFilterOption('grade_10', 'Grade 10'),
    _PathFilterOption('grade_11_natural', 'Grade 11 Natural Science'),
    _PathFilterOption('grade_11_social', 'Grade 11 Social Science'),
    _PathFilterOption('grade_12_natural', 'Grade 12 Natural Science'),
    _PathFilterOption('grade_12_social', 'Grade 12 Social Science'),
    _PathFilterOption('freshman_sem1_natural', 'Univ Freshman Sem 1 Natural'),
    _PathFilterOption('freshman_sem1_social', 'Univ Freshman Sem 1 Social'),
    _PathFilterOption('freshman_sem2_pre_eng', 'Univ Freshman Sem 2 Pre-Eng'),
    _PathFilterOption('freshman_sem2_other', 'Univ Freshman Sem 2 Other Nat'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final firebase = FirebaseService();
      final usersData =
          await firebase.getDocuments('users', orderBy: 'full_name');
      final users = usersData.map((data) => UserModel.fromJson(data)).toList();

      final adminData = await firebase.getAppSettings();
      final admins = adminData?['admin_emails'];

      setState(() {
        _users = users;
        _filteredUsers = List.from(users);
        _totalUsers = users.length;
        _activeUsers = users.where((u) => u.accountStatus != 'banned').length;
        _bannedUsers = users.where((u) => u.accountStatus == 'banned').length;
        _proUsers = users.where((u) => u.selectedPackage != 'free').length;
        _freeUsers = users.where((u) => u.selectedPackage == 'free').length;
        if (admins is List) {
          _adminEmails = List<String>.from(admins);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error loading users'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredUsers = _users.where((user) {
        if (_statusFilter == 'Active' && user.accountStatus == 'banned')
          return false;
        if (_statusFilter == 'Banned' && user.accountStatus != 'banned')
          return false;
        if (_subscriptionFilter == 'Pro' && user.selectedPackage == 'free')
          return false;
        if (_subscriptionFilter == 'Free' && user.selectedPackage != 'free')
          return false;
        if (_pathFilter != 'All') {
          final userPath = _getUserPath(user);
          if (userPath != _pathFilter) return false;
        }
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final name = user.fullName.toLowerCase();
          final email = user.email.toLowerCase();
          final phone = user.phoneNumber.toLowerCase();
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

  String _getUserPath(UserModel user) {
    if (user.academicLevel == 'high_school') {
      if (user.grade == '11' || user.grade == '12') {
        return 'grade_${user.grade}_${user.stream}';
      }
      return 'grade_${user.grade}';
    } else if (user.academicLevel == 'university') {
      if (user.semester == '2') {
        return 'freshman_sem2_${user.onboardingSelections?['track']}';
      }
      return 'freshman_sem1_${user.stream}';
    }
    return 'unknown';
  }

  // ============================================
  // FIXED: Added import for Uint8List
  // ============================================
  Future<Uint8List?> _fetchImageBytes(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching image: $e');
      return null;
    }
  }

  Future<void> _exportSingleUserPDF(UserModel user) async {
    setState(() => _isProcessing = true);
    try {
      final pdf = await _generateUserPDF(user, includeProfilePic: true);
      await _saveAndSharePDF(pdf, 'user_${user.fullName.replaceAll(' ', '_')}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User PDF generated and shared!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('PDF export failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _exportAllUsersPDF() async {
    setState(() {
      _isProcessing = true;
      _exportingAll = true;
    });
    try {
      final users = _filteredUsers.isNotEmpty ? _filteredUsers : _users;
      final pdf = await _generateAllUsersPDF(users);
      await _saveAndSharePDF(pdf,
          'all_users_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${users.length} users exported to PDF!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('PDF export failed: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
        _exportingAll = false;
      });
    }
  }

  // ============================================
  // FIXED: Proper PDF generation with correct types
  // ============================================
  Future<pw.Document> _generateUserPDF(UserModel user,
      {bool includeProfilePic = true}) async {
    final pdf = pw.Document();
    Uint8List? profileImage;
    if (includeProfilePic &&
        user.avatarUrl != null &&
        user.avatarUrl!.isNotEmpty) {
      profileImage = await _fetchImageBytes(user.avatarUrl);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ACADIA - User Profile',
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue)),
                  pw.Text(
                      'Generated: ${DateTime.now().toString().split(' ')[0]}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 16),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (profileImage != null)
                    pw.Container(
                      width: 80,
                      height: 80,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: PdfColors.blue, width: 2),
                      ),
                      child: pw.ClipOval(
                          child: pw.Image(pw.MemoryImage(profileImage))),
                    )
                  else
                    pw.Container(
                      width: 80,
                      height: 80,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: PdfColors.grey300,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : 'U',
                          style: pw.TextStyle(
                              fontSize: 32,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey600),
                        ),
                      ),
                    ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(user.fullName,
                            style: pw.TextStyle(
                                fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(user.email,
                            style: pw.TextStyle(
                                fontSize: 12, color: PdfColors.grey)),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            _buildStatusBadge(
                                user.selectedPackage != 'free' ? 'PRO' : 'FREE',
                                user.selectedPackage != 'free'
                                    ? PdfColors.green
                                    : PdfColors.grey),
                            pw.SizedBox(width: 8),
                            if (user.accountStatus == 'banned')
                              _buildStatusBadge('BANNED', PdfColors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('PERSONAL INFORMATION',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                      color: PdfColors.blue)),
              pw.Divider(),
              pw.SizedBox(height: 8),
              _buildInfoRowPdf('Full Name', user.fullName),
              _buildInfoRowPdf('Username', user.username),
              _buildInfoRowPdf('Email', user.email),
              _buildInfoRowPdf('Phone', user.phoneNumber),
              _buildInfoRowPdf(
                  'Registration Date', _formatDate(user.registrationDate)),
              _buildInfoRowPdf('Last Login', _formatDate(user.lastLogin)),
              _buildInfoRowPdf('Notification Preferences',
                  user.notificationPreferences.toString()),
              pw.SizedBox(height: 16),
              pw.Text('ACADEMIC PATH',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                      color: PdfColors.blue)),
              pw.Divider(),
              pw.SizedBox(height: 8),
              _buildInfoRowPdf('Academic Level', user.academicLevel),
              _buildInfoRowPdf('Grade', user.grade ?? ''),
              _buildInfoRowPdf('Stream', user.stream ?? ''),
              _buildInfoRowPdf('Department', user.department ?? ''),
              _buildInfoRowPdf('Year', user.year ?? ''),
              _buildInfoRowPdf('Semester', user.semester ?? ''),
              _buildInfoRowPdf('Track',
                  user.onboardingSelections?['track']?.toString() ?? ''),
              _buildInfoRowPdf('Generation',
                  user.onboardingSelections?['generation']?.toString() ?? ''),
              _buildInfoRowPdf(
                  'University',
                  user.onboardingSelections?['universityName']?.toString() ??
                      user.onboardingSelections?['university']?.toString() ??
                      ''),
              _buildInfoRowPdf(
                  'High School',
                  user.onboardingSelections?['highSchoolName']?.toString() ??
                      ''),
              pw.SizedBox(height: 16),
              pw.Text('SUBSCRIPTION',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                      color: PdfColors.blue)),
              pw.Divider(),
              pw.SizedBox(height: 8),
              _buildInfoRowPdf(
                  'Selected Package', user.selectedPackage ?? 'free'),
              _buildInfoRowPdf('Payment Status', user.paymentStatus ?? ''),
              _buildInfoRowPdf(
                  'Account Status', user.accountStatus ?? 'active'),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'ACADIA - Digital Education Platform',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Powered by NextGen Ethiopia',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  // ============================================
  // FIXED: Removed withOpacity, use direct colors
  // ============================================
  pw.Widget _buildStatusBadge(String text, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: color == PdfColors.green
            ? PdfColors.green100
            : color == PdfColors.red
                ? PdfColors.red100
                : PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: color),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
            fontSize: 9, fontWeight: pw.FontWeight.bold, color: color),
      ),
    );
  }

  // ============================================
  // FIXED: Correct fontWeight (bold not w500)
  // ============================================
  pw.Widget _buildInfoRowPdf(String label, String value) {
    if (value.isEmpty ||
        value.toLowerCase() == 'null' ||
        value.toLowerCase() == 'n/a') {
      return pw.SizedBox.shrink();
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  Future<pw.Document> _generateAllUsersPDF(List<UserModel> users) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('ACADIA - User Management Report',
                  style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue)),
              pw.SizedBox(height: 4),
              pw.Text(
                  'Generated: ${DateTime.now().toString().split(' ')[0]} at ${DateTime.now().toString().split(' ')[1]}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('SUMMARY STATISTICS',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Metric', 'Count'],
                  <String>['Total Users', users.length.toString()],
                  <String>[
                    'Active Users',
                    users
                        .where((u) => u.accountStatus != 'banned')
                        .length
                        .toString()
                  ],
                  <String>[
                    'Banned Users',
                    users
                        .where((u) => u.accountStatus == 'banned')
                        .length
                        .toString()
                  ],
                  <String>[
                    'Pro Users',
                    users
                        .where((u) => u.selectedPackage != 'free')
                        .length
                        .toString()
                  ],
                  <String>[
                    'Free Users',
                    users
                        .where((u) => u.selectedPackage == 'free')
                        .length
                        .toString()
                  ],
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text('USERS BY ACADEMIC PATH',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Path', 'Count'],
                  ..._getPathCounts(users)
                      .entries
                      .map((e) => <String>[e.key, e.value.toString()]),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text('TOTAL: ${users.length} users',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Center(
                child: pw.Text('ACADIA - Digital Education Platform',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    for (final user in users) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(user.fullName,
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(user.email,
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PERSONAL',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                  color: PdfColors.blue)),
                          pw.SizedBox(height: 4),
                          _buildInfoRowPdf('Name', user.fullName),
                          _buildInfoRowPdf('Username', user.username),
                          _buildInfoRowPdf('Email', user.email),
                          _buildInfoRowPdf('Phone', user.phoneNumber),
                          _buildInfoRowPdf(
                              'Registered', _formatDate(user.registrationDate)),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('ACADEMIC',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                  color: PdfColors.blue)),
                          pw.SizedBox(height: 4),
                          _buildInfoRowPdf('Level', user.academicLevel),
                          _buildInfoRowPdf('Grade', user.grade ?? ''),
                          _buildInfoRowPdf('Stream', user.stream ?? ''),
                          _buildInfoRowPdf(
                              'Package', user.selectedPackage ?? 'free'),
                          _buildInfoRowPdf(
                              'Status', user.accountStatus ?? 'active'),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.Center(
                  child: pw.Text('ACADIA - Digital Education Platform',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }

  Map<String, int> _getPathCounts(List<UserModel> users) {
    final counts = <String, int>{};
    for (final user in users) {
      final path = _getUserPathDisplay(user);
      counts[path] = (counts[path] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _saveAndSharePDF(pw.Document pdf, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final fullFileName =
        '${fileName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fullFileName');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'ACADIA User Report');
  }

  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: user.avatarUrl != null
                      ? () => _viewFullPhoto(user.avatarUrl!)
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3)),
                    child: ClipOval(
                      child: user.avatarUrl != null &&
                              user.avatarUrl!.isNotEmpty
                          ? Image.network(
                              user.avatarUrl!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: const Center(
                                        child: SizedBox(
                                            width: 30,
                                            height: 30,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))));
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Text(
                                      (user.fullName).isNotEmpty
                                          ? user.fullName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey),
                                    ),
                                  ),
                                );
                              },
                            )
                          : CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              child: Text(
                                (user.fullName).isNotEmpty
                                    ? user.fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                  child: Text(user.fullName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))),
              const SizedBox(height: 4),
              Center(child: _buildUserStatusBadge(user)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _exportSingleUserPDF(user),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export User as PDF'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              const Text('PERSONAL INFORMATION',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey)),
              const Divider(),
              _buildInfoRow('Full Name', user.fullName),
              _buildInfoRow('Username', user.username),
              _buildInfoRow('Email', user.email),
              _buildInfoRow('Phone', user.phoneNumber),
              _buildInfoRow(
                  'Registration Date', _formatDate(user.registrationDate)),
              _buildInfoRow('Last Login', _formatDate(user.lastLogin)),
              _buildInfoRow('Notification Preferences',
                  user.notificationPreferences.toString()),
              const SizedBox(height: 16),
              const Text('ACADEMIC PATH',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey)),
              const Divider(),
              _buildInfoRow('Academic Level', user.academicLevel),
              _buildInfoRow('Grade', user.grade),
              _buildInfoRow('Stream', user.stream),
              _buildInfoRow('Department', user.department),
              _buildInfoRow('Year', user.year),
              _buildInfoRow('Semester', user.semester),
              _buildInfoRow(
                  'Track', user.onboardingSelections?['track']?.toString()),
              _buildInfoRow('Generation',
                  user.onboardingSelections?['generation']?.toString()),
              _buildInfoRow(
                  'University',
                  user.onboardingSelections?['universityName']?.toString() ??
                      user.onboardingSelections?['university']?.toString()),
              _buildInfoRow('High School',
                  user.onboardingSelections?['highSchoolName']?.toString()),
              const SizedBox(height: 16),
              const Text('SUBSCRIPTION',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey)),
              const Divider(),
              _buildInfoRow('Selected Package', user.selectedPackage),
              _buildInfoRow('Payment Status', user.paymentStatus),
              _buildInfoRow('Account Status', user.accountStatus),
              const SizedBox(height: 20),
              const Text('ADMIN ACTIONS',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey)),
              const Divider(),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.6,
                children: [
                  _buildActionButton(
                      icon: user.selectedPackage != 'free'
                          ? Icons.block
                          : Icons.verified_user,
                      label: user.selectedPackage != 'free'
                          ? 'Revoke PRO'
                          : 'Grant PRO',
                      color: user.selectedPackage != 'free'
                          ? Colors.orange
                          : Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _toggleProStatus(user);
                      }),
                  _buildActionButton(
                      icon: user.accountStatus == 'banned'
                          ? Icons.check_circle
                          : Icons.cancel,
                      label: user.accountStatus == 'banned'
                          ? 'Unban User'
                          : 'Ban User',
                      color: user.accountStatus == 'banned'
                          ? Colors.green
                          : Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _toggleBanStatus(user);
                      }),
                  _buildActionButton(
                      icon: Icons.notifications_active,
                      label: 'Send Notification',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        _showSendNotificationDialog(user);
                      }),
                  _buildActionButton(
                      icon: Icons.delete_forever,
                      label: 'Delete User',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _deleteUser(user);
                      }),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewFullPhoto(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black87,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                        child: Icon(Icons.broken_image,
                            size: 64, color: Colors.grey));
                  },
                ),
              ),
            ),
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
          ],
        ),
      ),
    );
  }

  Future<void> _toggleProStatus(UserModel user) async {
    final isCurrentlyPro = user.selectedPackage != 'free';
    final confirmed = await _showConfirmDialog(
      '${isCurrentlyPro ? 'Revoke PRO' : 'Grant PRO'} for ${user.fullName}?',
      isCurrentlyPro
          ? 'This will remove the user\'s PRO access and revert to FREE package.'
          : 'This will unlock all premium content for the user immediately.',
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final firebase = FirebaseService();
      if (isCurrentlyPro) {
        await firebase.updateDocument('users', user.id, {
          'selected_package': 'free',
          'payment_status': 'pending',
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        final packageService = PackageService();
        await packageService.activatePackage(
          user.id,
          packageName:
              user.grade != null ? 'Grade ${user.grade}' : 'University',
          packageAmount: 0,
          paymentMethod: 'manual_admin',
        );
      }
      await _loadData();
      _applyFilters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${user.fullName}: ${isCurrentlyPro ? 'PRO revoked' : 'PRO activated!'}'),
              backgroundColor: isCurrentlyPro ? Colors.orange : Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _toggleBanStatus(UserModel user) async {
    final isCurrentlyBanned = user.accountStatus == 'banned';
    final confirmed = await _showConfirmDialog(
      '${isCurrentlyBanned ? 'Unban' : 'Ban'} ${user.fullName}?',
      isCurrentlyBanned
          ? 'This will restore the user\'s account access.'
          : 'This will prevent the user from logging in and accessing the app.',
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final firebase = FirebaseService();
      await firebase.updateDocument('users', user.id, {
        'account_status': isCurrentlyBanned ? 'active' : 'banned',
        'updated_at': DateTime.now().toIso8601String(),
      });
      await _loadData();
      _applyFilters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${user.fullName}: ${isCurrentlyBanned ? 'Unbanned' : 'Banned!'}'),
              backgroundColor: isCurrentlyBanned ? Colors.green : Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await _showConfirmDialog(
      'Delete ${user.fullName}?',
      'This action is PERMANENT and CANNOT be undone. All user data (profile, payments, progress) will be lost.',
    );
    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final firebase = FirebaseService();
      await firebase.deleteDocument('users', user.id);
      await _loadData();
      _applyFilters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${user.fullName} deleted'),
              backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showSendNotificationDialog(UserModel user) async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Notification to ${user.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Important Update',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  hintText: 'Type your notification message here...',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty ||
                  messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please fill in both title and message'),
                      backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('SEND'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final firebase = FirebaseService();
        final title = titleController.text.trim();
        final message = messageController.text.trim();
        final targetUserId = (user.id ?? '').trim();
        if (title.isEmpty || message.isEmpty || targetUserId.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Notification could not be sent: missing title, message, or user.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        await firebase.createNotification(
          title: title,
          message: message,
          targetUserId: targetUserId,
          type: 'system',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Notification sent!'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      } finally {
        titleController.dispose();
        messageController.dispose();
      }
    } else {
      titleController.dispose();
      messageController.dispose();
    }
  }

  Future<void> _showManageAdminsDialog() async {
    final emailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Manage Administrators'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Admins:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_adminEmails.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No admins configured',
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ..._adminEmails.map((email) => Card(
                          margin: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.admin_panel_settings,
                                size: 18),
                            title: Text(email,
                                style: const TextStyle(fontSize: 13)),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red, size: 18),
                              onPressed: () async {
                                await _removeAdmin(email);
                                setDialogState(() {});
                              },
                              tooltip: 'Remove admin',
                            ),
                          ),
                        )),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Add New Admin:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Admin Email',
                      border: const OutlineInputBorder(),
                      hintText: 'admin@example.com',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: AppColors.primary),
                        onPressed: () async {
                          final email = emailController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter a valid email'),
                                  backgroundColor: Colors.red),
                            );
                            return;
                          }
                          await _addAdmin(email);
                          emailController.clear();
                          setDialogState(() {});
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done')),
          ],
        ),
      ),
    );
    emailController.dispose();
  }

  Future<void> _addAdmin(String email) async {
    setState(() => _isProcessing = true);
    try {
      final firebase = FirebaseService();
      final settings = await firebase.getAppSettings() ?? {};
      final existing = List<String>.from(settings['admin_emails'] ?? []);
      final normalizedEmail = email.trim().toLowerCase();
      if (existing.map((e) => e.toLowerCase()).contains(normalizedEmail)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('$email is already an admin'),
                backgroundColor: Colors.orange),
          );
        }
        return;
      }
      existing.add(email.trim());
      await firebase.updateAppSettings({'admin_emails': existing});
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$email added as admin'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _removeAdmin(String email) async {
    setState(() => _isProcessing = true);
    try {
      final firebase = FirebaseService();
      final settings = await firebase.getAppSettings() ?? {};
      final existing = List<String>.from(settings['admin_emails'] ?? []);
      final normalizedEmail = email.trim().toLowerCase();
      final filtered = existing
          .where((e) => e.trim().toLowerCase() != normalizedEmail)
          .toList();
      await firebase.updateAppSettings({'admin_emails': filtered});
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$email removed from admins'),
              backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildUserStatusBadge(UserModel user) {
    final isPro = user.selectedPackage != 'free';
    final isBanned = user.accountStatus == 'banned';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isPro
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isPro ? Colors.green : Colors.grey),
          ),
          child: Text(isPro ? 'PRO' : 'FREE',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPro ? Colors.green : Colors.grey)),
        ),
        if (isBanned) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red),
            ),
            child: const Text('BANNED',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null ||
        value.isEmpty ||
        value.toLowerCase() == 'null' ||
        value.toLowerCase() == 'n/a') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 130,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
              child:
                  Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }

  String _getUserPathDisplay(UserModel user) {
    if (user.academicLevel == 'high_school') {
      if (user.grade == '11' || user.grade == '12') {
        return 'Grade ${user.grade} ${user.stream == 'natural' ? 'Natural Science' : 'Social Science'}';
      }
      return 'Grade ${user.grade}';
    } else if (user.academicLevel == 'university') {
      return 'Univ. ${user.department} - Year ${user.year}, Sem ${user.semester}';
    }
    return 'Unknown';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    try {
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return date.toString();
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        leading: IconButton(
            onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(
              onPressed: _showManageAdminsDialog,
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Manage Admins'),
          PopupMenuButton<String>(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Users',
            onSelected: (value) {
              if (value == 'export_all') {
                _exportAllUsersPDF();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_all',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Export All Users as PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard('Total', _totalUsers, AppColors.primary),
                const SizedBox(width: 8),
                _buildStatCard('Active', _activeUsers, Colors.green),
                const SizedBox(width: 8),
                _buildStatCard('Pro', _proUsers, Colors.purple),
                const SizedBox(width: 8),
                _buildStatCard('Free', _freeUsers, Colors.grey),
                const SizedBox(width: 8),
                _buildStatCard('Banned', _bannedUsers, Colors.red),
              ],
            ),
          ),
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) {
                _searchQuery = v;
                _applyFilters();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown(
                    'Path',
                    _pathFilter,
                    _pathOptions
                        .map((p) => DropdownMenuItem(
                            value: p.value,
                            child:
                                Text(p.label, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    (v) {
                      _pathFilter = v!;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterDropdown(
                    'Status',
                    _statusFilter,
                    _statusOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    (v) {
                      _statusFilter = v!;
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterDropdown(
                    'Sub',
                    _subscriptionFilter,
                    _subscriptionOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    (v) {
                      _subscriptionFilter = v!;
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${_filteredUsers.length} users',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const Spacer(),
                if (_exportingAll)
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                TextButton.icon(
                  onPressed: _exportAllUsersPDF,
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label:
                      const Text('Export All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Text('No users found',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isPro = user.selectedPackage != 'free';
                          final isBanned = user.accountStatus == 'banned';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () => _showUserDetails(user),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipOval(
                                      child: user.avatarUrl != null &&
                                              user.avatarUrl!.isNotEmpty
                                          ? Image.network(
                                              user.avatarUrl!,
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child: SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth:
                                                                    2)),
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: AppColors.primary
                                                      .withOpacity(0.1),
                                                  child: Center(
                                                    child: Text(
                                                      (user.fullName).isNotEmpty
                                                          ? user.fullName[0]
                                                              .toUpperCase()
                                                          : 'U',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              AppColors.primary,
                                                          fontSize: 18),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  (user.fullName).isNotEmpty
                                                      ? user.fullName[0]
                                                          .toUpperCase()
                                                      : 'U',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.primary,
                                                      fontSize: 18),
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(user.fullName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15)),
                                          Text(user.email,
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13)),
                                          Text(user.phoneNumber,
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12)),
                                          Text(_getUserPathDisplay(user),
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.primary)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isPro
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.grey.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(isPro ? 'PRO' : 'FREE',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isPro
                                                      ? Colors.green
                                                      : Colors.grey)),
                                        ),
                                        if (isBanned) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.red.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Text('BANNED',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ],
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(count.toString(),
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value,
      List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    final colorScheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: colorScheme.surface,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      isExpanded: true,
      style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _PathFilterOption {
  final String value;
  final String label;
  _PathFilterOption(this.value, this.label);
}
