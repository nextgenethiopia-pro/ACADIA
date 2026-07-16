import 'package:equatable/equatable.dart';

DateTime? _parseTimestamp(dynamic timestamp) {
  if (timestamp == null) return null;
  if (timestamp is DateTime) return timestamp;
  if (timestamp is String) {
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return null;
    }
  }
  try {
    return timestamp.toDate();
  } catch (e) {
    return null;
  }
}

enum PaymentStatus { pending, approved, rejected }
enum PaymentMethod { telebirr, mpesa, cbe, cbo, awash }

class PaymentModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String packageName;
  final int amount;
  final PaymentMethod method;
  final String senderAccount;
  final String transactionReference;
  final String? receiptImageUrl;
  final PaymentStatus status;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final DateTime submissionDate;

  const PaymentModel({
    required this.id,
    required this.userId,
    this.userName = '',
    this.userEmail = '',
    this.userPhone = '',
    required this.packageName,
    required this.amount,
    required this.method,
    required this.senderAccount,
    this.transactionReference = '',
    this.receiptImageUrl,
    this.status = PaymentStatus.pending,
    this.rejectionReason,
    this.approvedAt,
    required this.submissionDate,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      userEmail: json['user_email']?.toString() ?? '',
      userPhone: json['user_phone']?.toString() ?? '',
      packageName: json['package_name']?.toString() ?? json['package']?.toString() ?? '',
      amount: json['amount'] as int? ?? 0,
      method: _parsePaymentMethod(json['payment_method']?.toString() ?? json['method']?.toString() ?? ''),
      senderAccount: json['sender_account']?.toString() ?? json['account_number']?.toString() ?? '',
      transactionReference: json['transaction_ref']?.toString() ?? json['transaction_reference']?.toString() ?? '',
      receiptImageUrl: json['receipt_url']?.toString() ?? json['receipt_image_url']?.toString(),
      status: _parsePaymentStatus(json['status']?.toString() ?? ''),
      rejectionReason: json['rejection_reason']?.toString(),
      approvedAt: _parseTimestamp(json['approved_at']),
      submissionDate: _parseTimestamp(json['submission_date'] ?? json['created_at']) ?? DateTime.now(),
    );
  }

  static PaymentMethod _parsePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'telebirr': return PaymentMethod.telebirr;
      case 'mpesa': case 'm-pesa': return PaymentMethod.mpesa;
      case 'cbe': return PaymentMethod.cbe;
      case 'cbo': return PaymentMethod.cbo;
      case 'awash': case 'awash bank': return PaymentMethod.awash;
      default: return PaymentMethod.telebirr;
    }
  }

  static PaymentStatus _parsePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return PaymentStatus.approved;
      case 'rejected': return PaymentStatus.rejected;
      default: return PaymentStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'user_phone': userPhone,
      'package_name': packageName,
      'amount': amount,
      'payment_method': method.name,
      'sender_account': senderAccount,
      'transaction_ref': transactionReference,
      'receipt_url': receiptImageUrl,
      'status': status.name,
      'rejection_reason': rejectionReason,
      'approved_at': approvedAt?.toIso8601String(),
      'submission_date': submissionDate.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, packageName, amount, status];
}