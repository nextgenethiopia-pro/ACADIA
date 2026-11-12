import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart' as firebase;

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
  final firebase.FirebaseService _firebaseService = firebase.FirebaseService();

  /// Check if user has an active package
  Future<bool> hasActivePackage() async {
    final userId = _auth.currentUser?.uid;
    final prefs = await SharedPreferences.getInstance();

    // Fast local check first
    final cachedIsPro = prefs.getBool('is_pro') ?? false;
    final cachedPaymentStatus = prefs.getString('payment_status');
    if (cachedIsPro || cachedPaymentStatus == 'approved') {
      final cachedExpiryStr = prefs.getString('package_expiry_at');
      if (cachedExpiryStr != null) {
        final cachedExpiry = DateTime.tryParse(cachedExpiryStr);
        if (cachedExpiry != null && DateTime.now().isBefore(cachedExpiry)) {
          return true;
        }
      } else {
        // If no expiry date but is_pro is true, consider it active
        // but we should still verify with Firestore
        // We'll continue to Firestore check below
      }
    }

    if (userId == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      if (userData == null) return false;

      final isPro = userData['is_pro'] as bool? ?? (userData['payment_status'] == 'approved');
      if (!isPro) {
        // Clear stale cache if not pro
        if (cachedIsPro) {
          await prefs.setBool('is_pro', false);
          await prefs.setString('payment_status', 'free');
          await prefs.remove('package_expiry_at');
        }
        return false;
      }

      final expiryDate = _parseDate(userData['package_expiry_at'] ?? userData['valid_until']);
      if (expiryDate != null && DateTime.now().isAfter(expiryDate)) {
        // Package expired - clear cache
        await prefs.setBool('is_pro', false);
        await prefs.setString('payment_status', 'expired');
        await prefs.remove('package_expiry_at');
        return false;
      }

      // Update cache
      await prefs.setBool('is_pro', true);
      await prefs.setString('payment_status', 'approved');
      if (expiryDate != null) {
        await prefs.setString('package_expiry_at', expiryDate.toIso8601String());
      }

      return true;
    } catch (e) {
      debugPrint('Error checking package status: $e');
      // Fall back to cached value on error
      return cachedIsPro && cachedPaymentStatus == 'approved';
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

      final approvedAt = _parseDate(userData['package_approved_at']);
      final expiryDate = approvedAt?.add(const Duration(days: 365));
      
      if (expiryDate == null) return {'has_package': false, 'is_pro': true};

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
  Future<int> getPackagePrice({String? grade, String? schoolLevel}) async {
    try {
      final settingsDoc = await _firestore.collection('settings').doc('app').get();
      if (!settingsDoc.exists) return 300;

      final settings = settingsDoc.data();
      if (settings == null) return 300;

      final prices = settings['package_prices'] as Map<String, dynamic>?;
      if (prices == null) return 300;

      final prefs = await SharedPreferences.getInstance();
      final selectedGrade = grade ?? prefs.getString('grade') ?? prefs.getString('selected_grade') ?? '9';
      final path = (schoolLevel ?? prefs.getString('academic_path') ?? prefs.getString('academic_level') ?? '').toUpperCase();

      String priceKey;
      if (path == 'UNIVERSITY') {
        final universityYear = prefs.getString('selected_year') ?? prefs.getString('year') ?? 'freshman';
        priceKey = 'university_$universityYear';
      } else {
        priceKey = 'grade_$selectedGrade';
      }

      return prices[priceKey] as int? ?? 300;
    } catch (e) {
      debugPrint('Error getting package price: $e');
      return 300;
    }
  }

  /// Get package name automatically from user's saved onboarding academic path
  Future<String> getPackageName() async {
    final prefs = await SharedPreferences.getInstance();
    final path = (prefs.getString('academic_path') ?? prefs.getString('academic_level') ?? '').toUpperCase();
    final grade = prefs.getString('grade') ?? prefs.getString('selected_grade');
    final stream = (prefs.getString('stream') ?? prefs.getString('selected_stream') ?? '').toLowerCase();
    final semester = prefs.getString('semester');
    final track = (prefs.getString('track') ?? prefs.getString('selected_track') ?? '').toLowerCase();

    if (path == 'HIGH SCHOOL' || grade != null) {
      switch (grade) {
        case '9':
          return 'Grade 9 Package';
        case '10':
          return 'Grade 10 Package';
        case '11':
          return stream == 'social'
              ? 'Grade 11 Social Science Package'
              : 'Grade 11 Natural Science Package';
        case '12':
          return stream == 'social'
              ? 'Grade 12 Social Science Package'
              : 'Grade 12 Natural Science Package';
        default:
          return 'Grade 9 Package';
      }
    } else {
      if (semester == '2') {
        return track == 'pre_engineering'
            ? 'Freshman Semester 2 Pre-Engineering Package'
            : 'Freshman Semester 2 Other Natural Science Package';
      } else if (semester == '1') {
        return stream == 'social'
            ? 'Freshman Semester 1 Social Science Package'
            : 'Freshman Semester 1 Natural Science Package';
      }
      return 'University Package';
    }
  }

  /// Calculate expiry date from approval date (1 year)
  DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) return date.toDate();
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date);
    return null;
  }

  /// Update user package status (called by admin when approving payment or manual Pro activation)
  Future<void> activatePackage(String userId, {
    String? packageName,
    int? packageAmount,
    String? paymentMethod,
  }) async {
    try {
      final now = DateTime.now();
      final expiry = now.add(const Duration(days: 365));

      final updates = <String, dynamic>{
        'is_pro': true,
        'selected_package': packageName ?? 'pro',
        'payment_status': 'approved',
        'package_name': packageName,
        'package_amount': packageAmount ?? 300,
        'package_payment_method': paymentMethod ?? 'admin',
        'package_approved_at': now.toIso8601String(),
        'package_expiry_at': expiry.toIso8601String(),
        'valid_until': expiry.toIso8601String(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).set(updates, SetOptions(merge: true));

      // Create payment approval notification
      try {
        await _firebaseService.createNotification(
          title: 'Payment Approved!',
          message: 'Your payment for $packageName has been approved. Your package is now active.',
          targetUserId: userId,
          type: 'payment',
        );
      } catch (e) {
        // Don't block package activation if notification creation fails
        debugPrint('Failed to create payment approval notification: $e');
      }

      // Also update SharedPreferences local cache if this is the logged-in user
      if (_auth.currentUser?.uid == userId) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_pro', true);
        await prefs.setString('selected_package', packageName ?? 'pro');
        await prefs.setString('payment_status', 'approved');
        await prefs.setString('package_expiry_at', expiry.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error activating package: $e');
      rethrow;
    }
  }

  /// Revoke user package (called by admin)
  Future<void> revokePackage(String userId) async {
    try {
      final updates = <String, dynamic>{
        'is_pro': false,
        'selected_package': 'free',
        'payment_status': 'free',
        'package_approved_at': null,
        'package_expiry_at': null,
        'valid_until': null,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).set(updates, SetOptions(merge: true));

      if (_auth.currentUser?.uid == userId) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_pro', false);
        await prefs.setString('selected_package', 'free');
        await prefs.setString('payment_status', 'free');
        await prefs.remove('package_expiry_at');
      }
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
      } else if (date is String) {
        d = DateTime.parse(date);
      } else {
        return '';
      }
      return '${d.day}/${d.month}/${d.year}';
    } catch (e) {
      return '';
    }
  }
}