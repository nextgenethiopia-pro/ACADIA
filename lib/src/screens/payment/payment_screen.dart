import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:acadia/src/core/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/widgets/common/gradient_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'telebirr';
  final _accountNumberController = TextEditingController();
  final _transactionRefController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  String? _userGrade;
  String? _userStream;
  String? _userPath;
  String? _userSemester;
  String? _userTrack;
  Map<String, dynamic>? _userProfile;
  String _userPackageName = '';
  int _userPackagePrice = 300;

  // FreeImage.host API Key
  static const String _freeImageApiKey = '6d207e02198a847aa98d0a2a901485a5';

  // Telegram Bot Config
  static const String _telegramBotToken = '8768821280:AAHBymqTwrxWhbIlIY1lyx1PdF7K-sB22hE';
  static const String _adminChatId = '5221126249';

  // Receipt image
  File? _receiptFile;
  String? _receiptUrl;
  final ImagePicker _picker = ImagePicker();

  // Payment methods with details (from ACADIA spec)
  static const List<Map<String, dynamic>> _paymentMethods = [
    {
      'method': 'telebirr',
      'name': 'Telebirr',
      'phone': '0967870090',
      'holder': 'FIRAOL TADESA',
      'icon': Icons.phone_android,
      'color': Color(0xFF4CAF50),
    },
    {
      'method': 'mpesa',
      'name': 'M-PESA',
      'phone': '0705578277',
      'holder': 'BONA BAYU',
      'icon': Icons.phone_android,
      'color': Color(0xFF2196F3),
    },
    {
      'method': 'cbe',
      'name': 'CBE',
      'account': '1000720789985',
      'holder': 'FIRAOL TADESA',
      'icon': Icons.account_balance,
      'color': Color(0xFFFF9800),
    },
    {
      'method': 'cbo',
      'name': 'CBO',
      'account': '1016100072577',
      'holder': 'FIRAOL TADESA',
      'icon': Icons.account_balance,
      'color': Color(0xFF9C27B0),
    },
    {
      'method': 'awash',
      'name': 'AWASH BANK',
      'account': '01320500140900',
      'holder': 'FIRAOL TADESA',
      'icon': Icons.account_balance,
      'color': Color(0xFF795548),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _transactionRefController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userPath = prefs.getString('academic_path');
      _userGrade = prefs.getString('grade') ?? prefs.getString('selected_grade');
      _userStream = prefs.getString('stream') ?? prefs.getString('selected_stream');
      _userTrack = prefs.getString('selected_track');
      _userSemester = prefs.getString('semester') ?? '1';

      _determinePackage();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading payment data: $e');
    }
  }

  void _determinePackage() {
    if (_userPath == 'HIGH SCHOOL' || _userPath == 'high-school') {
      if (_userGrade == '9') {
        _userPackageName = 'Grade 9 Package';
      } else if (_userGrade == '10') {
        _userPackageName = 'Grade 10 Package';
      } else if (_userGrade == '11') {
        _userPackageName = _userStream == 'social' 
            ? 'Grade 11 Social Science Package' 
            : 'Grade 11 Natural Science Package';
      } else if (_userGrade == '12') {
        _userPackageName = _userStream == 'social' 
            ? 'Grade 12 Social Science Package' 
            : 'Grade 12 Natural Science Package';
      }
    } else if (_userPath == 'UNIVERSITY' || _userPath == 'university') {
      if (_userSemester == '2' && _userTrack == 'pre_engineering') {
        _userPackageName = 'Freshman Sem 2 Pre-Engineering Package';
      } else if (_userSemester == '2') {
        _userPackageName = 'Freshman Sem 2 Other Natural Science Package';
      } else if (_userStream == 'social') {
        _userPackageName = 'Freshman Sem 1 Social Science Package';
      } else {
        _userPackageName = 'Freshman Sem 1 Natural Science Package';
      }
    }
    _userPackagePrice = 300;
  }

  Map<String, dynamic> _getSelectedPaymentMethod() {
    return _paymentMethods.firstWhere((m) => m['method'] == _selectedMethod);
  }

  Future<String?> _uploadToFreeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      const uploadUrl = 'https://freeimage.host/api/1/upload';
      
      final dio = Dio();
      final formData = FormData.fromMap({
        'key': _freeImageApiKey,
        'action': 'upload',
        'source': MultipartFile.fromBytes(
          bytes,
          filename: 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'format': 'json',
      });
      
      final response = await dio.post(
        uploadUrl,
        data: formData,
        onSendProgress: (sent, total) {
          if (mounted) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
        },
      );
      
      if (response.statusCode == 200 && response.data['status_code'] == 200) {
        return response.data['image']['url'];
      } else {
        debugPrint('FreeImage.host upload failed: ${response.data}');
        return null;
      }
    } catch (e) {
      debugPrint('FreeImage.host upload error: $e');
      return null;
    }
  }

  Future<void> _pickReceipt() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _receiptFile = File(pickedFile.path);
          _receiptUrl = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _takeReceiptPhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _receiptFile = File(pickedFile.path);
          _receiptUrl = null;
        });
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  Future<void> _sendTelegramNotification(String userEmail, String receiptUrl) async {
    try {
      final method = _getSelectedPaymentMethod();
      final user = FirebaseAuth.instance.currentUser;
      final userName = user?.displayName ?? 'User';
      
      final message = '''
🚨 NEW PAYMENT SUBMISSION

👤 User: $userName
📧 Email: $userEmail
📱 Phone: ${user?.phoneNumber ?? 'N/A'}
📦 Package: $_userPackageName
💰 Amount: $_userPackagePrice ETB
💳 Method: ${method['name']}
🔢 Sender: ${_accountNumberController.text.trim()}
🧾 Ref: ${_transactionRefController.text.trim()}
🖼️ Receipt: $receiptUrl
⏰ Time: ${DateTime.now().toString().substring(0, 19)}
      ''';

      // Send text message
      await http.post(
        Uri.parse('https://api.telegram.org/bot$_telegramBotToken/sendMessage'),
        body: {'chat_id': _adminChatId, 'text': message, 'parse_mode': 'HTML'},
      );

      // Send receipt image
      if (_receiptFile != null) {
        final bytes = await _receiptFile!.readAsBytes();
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.telegram.org/bot$_telegramBotToken/sendPhoto'),
        )
          ..fields['chat_id'] = _adminChatId
          ..fields['caption'] = '📸 Payment Receipt - $userName (${_userPackageName})'
          ..files.add(http.MultipartFile.fromBytes('photo', bytes, filename: 'receipt.jpg'));

        await request.send();
      }
      
      debugPrint('Telegram notification sent successfully');
    } catch (e) {
      debugPrint('Error sending Telegram notification: $e');
    }
  }

  Future<void> _submitPayment() async {
    if (_accountNumberController.text.trim().isEmpty) {
      _showError('Please enter your account/phone number');
      return;
    }
    if (_receiptFile == null) {
      _showError('Please upload a receipt screenshot');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload receipt to FreeImage.host
      setState(() => _isUploading = true);
      final imageUrl = await _uploadToFreeImage(_receiptFile!);
      setState(() => _isUploading = false);
      
      if (imageUrl == null) {
        throw Exception('Failed to upload receipt. Please try again.');
      }

      final firebaseService = FirebaseService();
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'unknown';
      final userEmail = user?.email ?? '';
      final userName = user?.displayName ?? 'User';

      // Save payment to Firebase
      final paymentData = {
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'package_name': _userPackageName,
        'amount': _userPackagePrice,
        'payment_method': _selectedMethod,
        'sender_account': _accountNumberController.text.trim(),
        'transaction_ref': _transactionRefController.text.trim(),
        'receipt_url': imageUrl,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      await firebaseService.addDocument('payments', paymentData);

      // Send Telegram notification with receipt URL
      await _sendTelegramNotification(userEmail, imageUrl);

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _isUploading = false;
      });
      _showError('Error: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Payment Submitted'),
          ],
        ),
        content: const Text(
          'Your payment has been submitted for verification. Admin will review and approve your payment. You will receive a notification once approved.',
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('GO TO DASHBOARD'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final method = _getSelectedPaymentMethod();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            const Text('ORDER SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildOrderRow('Package', _userPackageName),
                    const SizedBox(height: 8),
                    _buildOrderRow('Validity', '1 Year from approval'),
                    const Divider(),
                    _buildOrderRow('Total', '$_userPackagePrice ETB', isBold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Method Selection
            const Text('SELECT PAYMENT METHOD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            ..._paymentMethods.map((m) {
              final isSelected = _selectedMethod == m['method'];
              final color = m['color'] as Color;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isSelected ? color : Colors.grey[200]!, width: isSelected ? 2 : 1),
                ),
                child: RadioListTile<String>(
                  value: m['method'],
                  groupValue: _selectedMethod,
                  onChanged: (v) => setState(() => _selectedMethod = v!),
                  title: Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(m['phone'] != null ? 'Phone: ${m['phone']}' : 'Account: ${m['account']}'),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(m['icon'] as IconData, color: isSelected ? color : Colors.grey, size: 24),
                  ),
                  activeColor: color,
                ),
              );
            }),
            const SizedBox(height: 24),

            // Payment Account Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pay to:', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (method['phone'] != null)
                    _buildAccountRow('Phone', method['phone']),
                  if (method['account'] != null)
                    _buildAccountRow('Account', method['account']),
                  _buildAccountRow('Holder', method['holder']),
                  const Divider(),
                  _buildAccountRow('Amount', '$_userPackagePrice ETB'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Transaction Details
            const Text('TRANSACTION DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(
              controller: _accountNumberController,
              decoration: InputDecoration(
                labelText: 'Your Account Number / Phone',
                hintText: 'Enter the account/phone number you used for payment',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _transactionRefController,
              decoration: InputDecoration(
                labelText: 'Transaction Reference (Optional)',
                hintText: 'Enter transaction ID or reference number',
                prefixIcon: const Icon(Icons.receipt),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Upload Receipt
            const Text('UPLOAD PAYMENT RECEIPT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            _buildReceiptUploader(),
            const SizedBox(height: 32),

            // Submit Button
            GradientButton(
              text: _isSubmitting ? 'SUBMITTING...' : 'CONFIRM PAYMENT',
              onPressed: _isSubmitting || _isUploading ? () {} : _submitPayment,
              isLoading: _isSubmitting || _isUploading,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: isBold ? 18 : 14)),
      ],
    );
  }

  Widget _buildAccountRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildReceiptUploader() {
    if (_isUploading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(value: _uploadProgress),
            const SizedBox(height: 12),
            Text('Uploading to FreeImage.host: ${(_uploadProgress * 100).toInt()}%'),
          ],
        ),
      );
    }

    if (_receiptFile != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(_receiptFile!, fit: BoxFit.cover),
            ),
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => setState(() => _receiptFile = null),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
                child: const Text('Receipt Selected ✓', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _pickReceipt,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                const Text('TAP TO SELECT SCREENSHOT', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Upload receipt screenshot', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _pickReceipt,
              icon: const Icon(Icons.photo_library, size: 18),
              label: const Text('Gallery'),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: _takeReceiptPhoto,
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('Camera'),
            ),
          ],
        ),
      ],
    );
  }
}