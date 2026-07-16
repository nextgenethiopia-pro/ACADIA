import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// PackageService - Manages package purchases, validity, and chapter locking
///
/// Features:
/// - Check if user's package is active and valid
/// - Validate 1-year expiry from admin approval date
/// - Lock/unlock chapters based on package status
/// - Track package purchase history
class PackageService {
  static final PackageService _instance = PackageService._internal();
  factory PackageService() => _instance;
  PackageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if user has an active package
  Future<bool> hasActivePackage() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      if (userData == null) return false;

      final isPro = userData['is_pro'] as bool? ?? false;
      if (!isPro) return false;

      final approvedAt = userData['package_approved_at'];
      if (approvedAt == null) return false;

      final expiryDate = _getExpiryDate(approvedAt);
      return DateTime.now().isBefore(expiryDate);
    } catch (e) {
      debugPrint('Error checking package status: $e');
      return false;
    }
  }

  /// Get all package info in one call
  Future<Map<String, dynamic>> getUserPackageInfo() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {'has_package': false};

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return {'has_package': false};

      final userData = userDoc.data()!;
      final isPro = userData['is_pro'] as bool? ?? false;

      if (!isPro) return {'has_package': false, 'is_pro': false};

      final approvedAt = userData['package_approved_at'];
      if (approvedAt == null) return {'has_package': false, 'is_pro': true};

      final expiryDate = _getExpiryDate(approvedAt);
      final now = DateTime.now();
      final isExpired = now.isAfter(expiryDate);
      final daysRemaining = isExpired ? 0 : expiryDate.difference(now).inDays;

      return {
        'has_package': true,
        'is_pro': true,
        'is_expired': isExpired,
        'days_remaining': daysRemaining,
        'expiry_date': expiryDate.toIso8601String(),
        'package_name': userData['package_name'] ?? '',
        'package_amount': userData['package_amount'] ?? 300,
        'approved_at': _formatDate(approvedAt),
        'expiring_soon': daysRemaining > 0 && daysRemaining <= 7,
      };
    } catch (e) {
      debugPrint('Error getting package info: $e');
      return {'has_package': false};
    }
  }

  /// Get days remaining until package expiry
  Future<int> getDaysRemaining() async {
    final info = await getUserPackageInfo();
    return info['days_remaining'] as int? ?? 0;
  }

  /// Check if package has expired
  Future<bool> isPackageExpired() async {
    final info = await getUserPackageInfo();
    return info['is_expired'] as bool? ?? true;
  }

  /// Get package price for user's grade
  Future<int> getPackagePrice() async {
    try {
      final settingsDoc = await _firestore.collection('settings').doc('app').get();
      if (!settingsDoc.exists) return 300;

      final settings = settingsDoc.data();
      if (settings == null) return 300;

      final prices = settings['package_prices'] as Map<String, dynamic>?;
      if (prices == null) return 300;

      final prefs = await SharedPreferences.getInstance();
      final grade = prefs.getString('grade') ?? '9';
      final schoolLevel = prefs.getString('school_level') ?? 'high-school';

      String priceKey;
      if (schoolLevel == 'university') {
        final universityYear = prefs.getString('university_year') ?? 'freshman';
        priceKey = 'university_$universityYear';
      } else {
        priceKey = 'grade_$grade';
      }

      return prices[priceKey] as int? ?? 300;
    } catch (e) {
      debugPrint('Error getting package price: $e');
      return 300;
    }
  }

  /// Get package name for user's academic path
  Future<String> getPackageName() async {
    final prefs = await SharedPreferences.getInstance();
    final grade = prefs.getString('grade') ?? '9';
    final schoolLevel = prefs.getString('school_level') ?? 'high-school';

    if (schoolLevel == 'university') {
      final universityYear = prefs.getString('university_year') ?? 'freshman';
      return 'University $universityYear Package';
    }

    return 'Grade $grade Package';
  }

  /// Calculate expiry date from approval date (1 year)
  DateTime _getExpiryDate(dynamic approvedAt) {
    DateTime approvalDate;

    if (approvedAt is Timestamp) {
      approvalDate = approvedAt.toDate();
    } else if (approvedAt is DateTime) {
      approvalDate = approvedAt;
    } else if (approvedAt is String) {
      approvalDate = DateTime.parse(approvedAt);
    } else {
      approvalDate = DateTime.now();
    }

    return approvalDate.add(const Duration(days: 365));
  }

  /// Update user package status (called by admin when approving payment)
  Future<void> activatePackage(String userId, {
    String? packageName,
    int? packageAmount,
    String? paymentMethod,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'is_pro': true,
        'package_approved_at': FieldValue.serverTimestamp(),
        'package_expiry_at': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 365)),
        ),
        'package_name': packageName,
        'package_amount': packageAmount,
        'package_payment_method': paymentMethod,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error activating package: $e');
      rethrow;
    }
  }

  /// Revoke user package (called by admin)
  Future<void> revokePackage(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'is_pro': false,
        'package_approved_at': null,
        'package_expiry_at': null,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error revoking package: $e');
      rethrow;
    }
  }

  /// Check if user's package will expire soon (within 7 days)
  Future<bool> isExpiringSoon() async {
    final info = await getUserPackageInfo();
    return info['expiring_soon'] as bool? ?? false;
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      DateTime d;
      if (date is Timestamp) {
        d = date.toDate();
      } else if (date is DateTime) {
        d = date;
      } else {
        d = DateTime.parse(date.toString());
      }
      return '${d.day}/${d.month}/${d.year}';
    } catch (e) {
      return '';
    }
  }
}