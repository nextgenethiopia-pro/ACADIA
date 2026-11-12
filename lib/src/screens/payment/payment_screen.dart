import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/constants/payment_methods.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:acadia/src/core/services/imgbb_service.dart';
import 'package:acadia/src/core/services/package_service.dart';
import 'package:acadia/src/core/services/payment_notification_service.dart';
import 'package:acadia/src/widgets/common/gradient_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senderAccountController = TextEditingController();
  final _transactionRefController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _selectedMethod = PaymentMethods.allMethods.first['id'] ?? 'telebirr';
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isUploading = false;
  double _uploadProgress = 0;

  String? _userPath;
  String? _userGrade;
  String? _userStream;
  String? _userSemester;
  String? _userTrack;
  String? _userGeneration;
  String? _userUniversity;
  String _packageName = '';
  int _packagePrice = 300;

  File? _receiptFile;
  String? _receiptUrl;

  @override
  void initState() {
    super.initState();
    _loadPaymentContext();
  }

  @override
  void dispose() {
    _senderAccountController.dispose();
    _transactionRefController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _userPath = prefs.getString('academic_path');
      _userGrade =
          prefs.getString('grade') ?? prefs.getString('selected_grade');
      _userStream =
          prefs.getString('stream') ?? prefs.getString('selected_stream');
      _userSemester = prefs.getString('semester');
      _userTrack = prefs.getString('selected_track');
      _userGeneration = prefs.getString('selected_generation') ??
          prefs.getString('generation');
      _userUniversity = prefs.getString('university_name') ??
          prefs.getString('selected_university') ??
          prefs.getString('university');

      _determinePackage();
      _packagePrice = await _resolvePackagePrice();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Payment context load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _determinePackage() {
    final path = (_userPath ?? '').toUpperCase();
    final stream = (_userStream ?? '').toLowerCase();
    final semester = (_userSemester ?? '').trim();
    final track = (_userTrack ?? '').toLowerCase();

    if (path == 'HIGH SCHOOL' || _userGrade != null) {
      switch (_userGrade) {
        case '9':
          _packageName = 'Grade 9 Package';
          break;
        case '10':
          _packageName = 'Grade 10 Package';
          break;
        case '11':
          _packageName = stream == 'social'
              ? 'Grade 11 Social Science Package'
              : 'Grade 11 Natural Science Package';
          break;
        case '12':
          _packageName = stream == 'social'
              ? 'Grade 12 Social Science Package'
              : 'Grade 12 Natural Science Package';
          break;
        default:
          _packageName = 'Grade 9 Package';
      }
    } else {
      if (semester == '2') {
        _packageName = track == 'pre_engineering'
            ? 'Freshman Semester 2 Pre-Engineering Package'
            : 'Freshman Semester 2 Other Natural Science Package';
      } else {
        _packageName = stream == 'social'
            ? 'Freshman Semester 1 Social Science Package'
            : 'Freshman Semester 1 Natural Science Package';
      }
    }

    _packagePrice = 300;
  }

  Future<int> _resolvePackagePrice() async {
    final prefs = await SharedPreferences.getInstance();
    final grade = prefs.getString('grade') ?? _userGrade ?? '9';
    final schoolLevel = prefs.getString('academic_level') ?? (_userPath?.toLowerCase() ?? 'high_school');
    return PackageService().getPackagePrice(grade: grade, schoolLevel: schoolLevel);
  }

  Map<String, String> _selectedMethodData() {
    return PaymentMethods.getMethodById(_selectedMethod) ??
        PaymentMethods.allMethods.first;
  }

  /// Brand logo for each payment method (bundled from assets/icons).
  String? _methodIconAsset(String methodId) {
    switch (methodId) {
      case 'telebirr':
        return 'assets/icons/telebirr_icon.png';
      case 'mpesa':
        return 'assets/icons/m-pesa_icon.png';
      case 'cbe':
        return 'assets/icons/cbe_birr_icon.png';
      case 'cbo':
        return 'assets/icons/cbo_bank_icon.png';
      case 'awash':
        return 'assets/icons/awash_bank_icon.png';
      default:
        return null;
    }
  }

  Widget _buildMethodIcon(String methodId, {double size = 24}) {
    final asset = _methodIconAsset(methodId);
    if (asset == null) {
      return Icon(Icons.account_balance, size: size, color: AppColors.primary);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.account_balance,
          size: size,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(String value, {String label = 'Account number'}) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value.trim()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied: ${value.trim()}'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _accountLabelForMethod(String methodId) {
    switch (methodId) {
      case 'telebirr':
      case 'mpesa':
        return 'Phone Number';
      default:
        return 'Account Number';
    }
  }

  String _senderLabelForMethod(String methodId) {
    switch (methodId) {
      case 'telebirr':
      case 'mpesa':
        return 'Your Sending Phone Number';
      default:
        return 'Your Sending Account Number';
    }
  }

  Color _methodAccent(String methodId) {
    switch (methodId) {
      case 'telebirr':
        return AppColors.primary;
      case 'mpesa':
        return AppColors.primaryLight;
      case 'cbe':
        return AppColors.primaryDark;
      case 'cbo':
        return AppColors.primary;
      case 'awash':
        return AppColors.primaryLight;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _pickReceipt(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (file == null) return;

      if (!mounted) return;
      setState(() {
        _receiptFile = File(file.path);
        _receiptUrl = null;
      });
    } catch (e) {
      _showError('Unable to select receipt image.');
      debugPrint('Receipt pick error: $e');
    }
  }

  Future<String> _uploadReceiptToImgBB(File file) async {
    if (mounted) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.2;
      });
    }

    try {
      final url = await ImgbbService.uploadImage(file);

      if (mounted) {
        setState(() {
          _uploadProgress = 1;
        });
      }

      return url;
    } catch (e, stackTrace) {
      debugPrint('[PaymentScreen] receipt upload failed: $e');
      debugPrint('$stackTrace');
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_receiptFile == null) {
      _showError('Please upload your payment receipt.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uploadedUrl = await _uploadReceiptToImgBB(_receiptFile!);

      final user = FirebaseAuth.instance.currentUser;
      final firebase = FirebaseService();

      final paymentData = <String, dynamic>{
        'user_id': user?.uid,
        'user_email': user?.email,
        'user_name': user?.displayName ?? 'Student',
        'user_phone': _senderAccountController.text.trim(),
        'academic_path': _userPath,
        'grade': _userGrade,
        'stream': _userStream,
        'semester': _userSemester,
        'track': _userTrack,
        'generation': _userGeneration,
        'university': _userUniversity,
        'package': _packageName,
        'package_name': _packageName,
        'amount': _packagePrice,
        'payment_method': _selectedMethod,
        'receiver_account': _selectedMethodData()['account'],
        'receiver_name': _selectedMethodData()['holder'],
        'sender_account': _senderAccountController.text.trim(),
        'transaction_ref': _transactionRefController.text.trim(),
        'receipt_url': uploadedUrl,
        'screenshot_url': uploadedUrl,
        'status': 'pending',
        'uploaded_via': 'imgbb',
        'submission_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      }..removeWhere((key, value) => value == null);

      if (kDebugMode) {
        print('Submitting payment data: $paymentData');
      }
      final paymentId = await firebase.addDocument('payments', paymentData);

      // Forward the payment to the administrator on Telegram through the
      // backend. A notification failure must never block a submitted payment.
      await PaymentNotificationService().notifyPaymentSubmitted(
        userId: user?.uid ?? '',
        paymentId: paymentId,
        amount: _packagePrice,
        method: _selectedMethod,
        reference: _transactionRefController.text.trim(),
        packageName: _packageName,
        userName: user?.displayName ?? 'Student',
        userEmail: user?.email,
        userPhone: _senderAccountController.text.trim(),
        screenshotUrl: uploadedUrl,
        submittedAt: paymentData['submission_date'] as String?,
      );

      if (!mounted) return;
      setState(() {
        _receiptUrl = uploadedUrl;
        _isSubmitting = false;
      });
      _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Expanded(child: Text('Payment Submitted')),
            ],
          ),
          content: Text(
            'Your payment for $_packageName has been submitted successfully. '
            'The NextGen team will review your receipt and approve it as soon as possible.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/payment-history');
              },
              child: const Text('VIEW HISTORY'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('DONE'),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: AppColors.primary, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final method = _selectedMethodData();
    final accent = _methodAccent(_selectedMethod);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          onPressed: _isSubmitting ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          TextButton(
            onPressed:
                _isSubmitting ? null : () => context.push('/payment-history'),
            child: const Text('History'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPackageCard(),
                const SizedBox(height: 20),
                _buildMethodSelector(accent),
                const SizedBox(height: 20),
                _buildPaymentDetailsCard(method, accent),
                const SizedBox(height: 20),
                _buildSenderDetailsCard(),
                const SizedBox(height: 20),
                _buildReceiptCard(accent),
                if (_isUploading) ...[
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: _uploadProgress <= 0 ? null : _uploadProgress,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uploading receipt to ImgBB...',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                GradientButton(
                  text: 'SUBMIT PAYMENT',
                  onPressed: _isSubmitting ? () {} : _submitPayment,
                  isLoading: _isSubmitting,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Your payment will remain pending until it is approved by admin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard() {
    final subtitleParts = <String>[];

    if ((_userPath ?? '').toUpperCase() == 'HIGH SCHOOL') {
      if ((_userGrade ?? '').isNotEmpty) {
        subtitleParts.add('Grade $_userGrade');
      }
      if ((_userStream ?? '').toLowerCase() == 'natural') {
        subtitleParts.add('Natural Science');
      } else if ((_userStream ?? '').toLowerCase() == 'social') {
        subtitleParts.add('Social Science');
      }
    } else {
      if ((_userGeneration ?? '').isNotEmpty) {
        subtitleParts.add(_userGeneration!);
      }
      if ((_userUniversity ?? '').isNotEmpty) {
        subtitleParts.add(_userUniversity!);
      }
      if ((_userSemester ?? '').isNotEmpty) {
        subtitleParts.add('Semester $_userSemester');
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium, color: AppColors.primary),
              SizedBox(width: 10),
              Text(
                'Selected Package',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _packageName,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          if (subtitleParts.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitleParts.join(' • '),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text(
                  'Amount',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '$_packagePrice ETB',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: PaymentMethods.allMethods.map((method) {
            final id = method['id'] ?? '';
            final isSelected = id == _selectedMethod;

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _isSubmitting
                  ? null
                  : () {
                      setState(() {
                        _selectedMethod = id;
                      });
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade300,
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMethodIcon(id, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      method['name'] ?? '',
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentDetailsCard(Map<String, String> method, Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildMethodIcon(method['id'] ?? '', size: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  method['name'] ?? 'Payment Method',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            _accountLabelForMethod(_selectedMethod),
            method['account'] ?? '',
            copyable: true,
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Account Holder', method['holder'] ?? ''),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Send exactly $_packagePrice ETB to the account above, then upload a clear receipt screenshot below.',
              style: TextStyle(
                color: Colors.grey.shade800,
                height: 1.45,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Payment Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _senderAccountController,
            enabled: !_isSubmitting,
            decoration: _inputDecoration(
              label: _senderLabelForMethod(_selectedMethod),
              hint: 'Enter the sender account or phone number',
              icon: Icons.person_outline,
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Please enter your sending account details';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _transactionRefController,
            enabled: !_isSubmitting,
            decoration: _inputDecoration(
              label: 'Transaction Reference',
              hint: 'Optional but recommended',
              icon: Icons.receipt_long_outlined,
              helperText:
                  'Use the reference shown on your payment receipt if available',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Receipt',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _isSubmitting
                ? null
                : () {
                    _showReceiptSourceSheet();
                  },
            child: Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.14),
                  style: BorderStyle.solid,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _receiptFile == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 44,
                          color: accent,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tap to upload receipt',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Receipt uploads are hosted using ImgBB',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_receiptFile!, fit: BoxFit.cover),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: InkWell(
                            onTap: _isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _receiptFile = null;
                                      _receiptUrl = null;
                                    });
                                  },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _pickReceipt(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _pickReceipt(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Camera'),
                ),
              ),
            ],
          ),
          if (_receiptUrl != null) ...[
            const SizedBox(height: 10),
            Text(
              'Receipt uploaded successfully to ImgBB.',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReceiptSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Upload Receipt',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickReceipt(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickReceipt(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool copyable = false}) {
    final valueStyle = const TextStyle(
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    );

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: copyable
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(child: SelectableText(value, style: valueStyle)),
                    const SizedBox(width: 8),
                    Icon(Icons.copy_rounded,
                        size: 16, color: AppColors.primary),
                  ],
                )
              : SelectableText(value, style: valueStyle),
        ),
      ],
    );

    if (!copyable) return row;

    return InkWell(
      onTap: () => _copyToClipboard(value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      ),
    );
  }
}
