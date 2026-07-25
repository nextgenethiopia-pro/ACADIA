import '../../core/services/firebase_service.dart';
import '../../domain/repositories/payment_repository.dart';

/// [PaymentRepository] implementation delegating to [FirebaseService].
class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._service);

  final FirebaseService _service;

  @override
  Future<void> submitPayment({
    required String amount,
    required String paymentMethod,
    required String transactionId,
    required String screenshotUrl,
  }) =>
      _service.submitPayment(
        amount: amount,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        screenshotUrl: screenshotUrl,
      );

  @override
  Future<void> submitPaymentRaw(Map<String, dynamic> paymentData) =>
      _service.submitPaymentRaw(paymentData);

  @override
  Future<List<Map<String, dynamic>>> getUserPayments() =>
      _service.getUserPayments();

  @override
  Future<List<Map<String, dynamic>>> getAllPayments() =>
      _service.getAllPayments();

  @override
  Future<void> updatePaymentStatus(String paymentId, String status) =>
      _service.updatePaymentStatus(paymentId, status);
}
