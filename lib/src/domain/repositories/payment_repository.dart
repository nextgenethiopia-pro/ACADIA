/// Contract for payment submission and approval.
///
/// Implemented by [PaymentRepositoryImpl] over `FirebaseService`. Covers the
/// user submit-receipt flow and the admin approval flow.
abstract class PaymentRepository {
  /// Submits a structured payment (amount, method, txn id, screenshot).
  Future<void> submitPayment({
    required String amount,
    required String paymentMethod,
    required String transactionId,
    required String screenshotUrl,
  });

  /// Submits a payment from a raw data map.
  Future<void> submitPaymentRaw(Map<String, dynamic> paymentData);

  /// Payments for the current user (newest first).
  Future<List<Map<String, dynamic>>> getUserPayments();

  /// All payments (admin, newest first).
  Future<List<Map<String, dynamic>>> getAllPayments();

  /// Updates a payment's status (approved/rejected/pending).
  Future<void> updatePaymentStatus(String paymentId, String status);
}
