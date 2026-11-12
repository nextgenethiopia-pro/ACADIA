import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Firebase Service (Firestore + Auth)
/// Firestore stores: Users, Payments, Notifications, App Settings, Analytics.
/// Progress is stored locally only (SharedPreferences).
/// Educational content is served from GitHub (not Firestore).
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;

  // ============================================
  // APPROVED FIRESTORE OPERATIONS
  // ============================================

  static const Set<String> _allowedCollections = {
    'users',
    'payments',
    'notifications',
    'settings',
    'analytics',
  };

  void _validateCollection(String collection) {
    if (!_allowedCollections.contains(collection)) {
      throw ArgumentError.value(
        collection,
        'collection',
        'Firestore is restricted to users, payments, notifications, settings, and analytics.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getDocuments(
    String collection, {
    Map<String, dynamic>? where,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      _validateCollection(collection);
      Query query = _firestore.collection(collection);

      if (where != null) {
        where.forEach((key, value) {
          query = query.where(key, isEqualTo: value);
        });
      }

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      debugPrint('Error getting documents from $collection: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getDocument(
      String collection, String docId) async {
    try {
      _validateCollection(collection);
      final doc = await _firestore.collection(collection).doc(docId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Error getting document $collection/$docId: $e');
      return null;
    }
  }

  Future<String> addDocument(
      String collection, Map<String, dynamic> data) async {
    try {
      _validateCollection(collection);
      final docRef = await _firestore.collection(collection).add({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding document to $collection: $e');
      rethrow;
    }
  }

  Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    try {
      _validateCollection(collection);
      await _firestore.collection(collection).doc(docId).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating document $collection/$docId: $e');
      rethrow;
    }
  }

  Future<void> deleteDocument(String collection, String docId) async {
    try {
      _validateCollection(collection);
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      debugPrint('Error deleting document $collection/$docId: $e');
      rethrow;
    }
  }

  // ============================================
  // USER PROFILES
  // ============================================

  Future<Map<String, dynamic>?> getUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> createUserProfile(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    await _firestore.collection('users').doc(userId).set({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    await _firestore.collection('users').doc(userId).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ============================================
  // USER PROGRESS (Local Only — never Firestore)
  // ============================================

  Future<void> saveUnitProgress({
    required String unitName,
    required String subjectId,
    required double progress,
    required bool isCompleted,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'progress_${subjectId}_$unitName';
    final encoded = json.encode({
      'unit_name': unitName,
      'subject_id': subjectId,
      'progress': progress,
      'is_completed': isCompleted,
      'updated_at': DateTime.now().toIso8601String(),
    });
    await prefs.setString(key, encoded);
  }

  Future<List<Map<String, dynamic>>> getUserProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('progress_'));
    final List<Map<String, dynamic>> allProgress = [];
    for (final key in keys) {
      final str = prefs.getString(key);
      if (str != null) {
        try {
          final map = json.decode(str) as Map<String, dynamic>;
          allProgress.add(map);
        } catch (_) {}
      }
    }
    return allProgress;
  }

  // ============================================
  // PAYMENTS
  // ============================================

  Future<void> submitPayment({
    required String amount,
    required String paymentMethod,
    required String transactionId,
    required String screenshotUrl,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    await _firestore.collection('payments').add({
      'user_id': userId,
      'amount': amount,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'screenshot_url': screenshotUrl,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitPaymentRaw(Map<String, dynamic> paymentData) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    await _firestore.collection('payments').add({
      ...paymentData,
      'user_id': userId,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getUserPayments() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final query = await _firestore
        .collection('payments')
        .where('user_id', isEqualTo: userId)
        .get();

    final payments =
        query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

    payments.sort((a, b) {
      final aTime = a['created_at'] ?? '';
      final bTime = b['created_at'] ?? '';
      return bTime.toString().compareTo(aTime.toString());
    });

    return payments;
  }

  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final query = await _firestore
        .collection('payments')
        .orderBy('created_at', descending: true)
        .get();

    return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> updatePaymentStatus(String paymentId, String status) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  Future<void> createNotification({
    required String title,
    required String message,
    String? targetUserId,
    String? targetGrade,
    required String type,
  }) async {
    await _firestore.collection('notifications').add({
      'title': title,
      'message': message,
      'target_user_id': targetUserId,
      'target_grade': targetGrade,
      'type': type,
      'created_by': currentUserId,
      'created_at': FieldValue.serverTimestamp(),
      'is_read': false,
    });
  }

  Future<List<Map<String, dynamic>>> getUserNotifications() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final query = await _firestore
        .collection('notifications')
        .orderBy('created_at', descending: true)
        .get();

    final allNotifications =
        query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

    return allNotifications.where((n) {
      final type = (n['type'] as String? ?? '').toLowerCase();
      final targetUserId = n['target_user_id'] as String?;
      final legacyUserId = n['user_id'] as String?;

      // Strict-user-scoped types: require a resolved recipient match.
      // Never broadcast payment or welcome notifications (even legacy).
      const strictTypes = {'payment', 'welcome'};
      if (strictTypes.contains(type)) {
        final resolved = (targetUserId ?? legacyUserId ?? '').trim();
        return resolved.isNotEmpty && resolved == userId;
      }

      // Single-user admin/system notifications: when a recipient is present,
      // respect it; do not fall back to broadcasting.
      final hasExplicitTarget = (targetUserId ?? '').trim().isNotEmpty ||
          (legacyUserId ?? '').trim().isNotEmpty;
      if (hasExplicitTarget) {
        final resolved = (targetUserId ?? legacyUserId ?? '').trim();
        return resolved == userId;
      }

      // Everything else without a target is treated as a broadcast
      // (e.g. admin announcements, content updates, grade-level blasts).
      return true;
    }).toList();
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'is_read': true,
    });
  }

  // ============================================
  // APP SETTINGS
  // ============================================

  Future<Map<String, dynamic>?> getAppSettings() async {
    final doc = await _firestore.collection('settings').doc('app').get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> updateAppSettings(Map<String, dynamic> settings) async {
    await _firestore.collection('settings').doc('app').set({
      ...settings,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ============================================
  // USER ACTIVITY & ACHIEVEMENTS
  // ============================================
  // Activity and achievements are now stored locally in Isar/OfflineDatabase
  // These methods are deprecated and return empty data

  @Deprecated('Use OfflineDatabase for activity tracking')
  Future<List<Map<String, dynamic>>> getUserActivity() async {
    return [];
  }

  @Deprecated('Use OfflineDatabase for activity logging')
  Future<void> logActivity(String action, String details) async {
    // No-op - activity is tracked locally
  }

  @Deprecated('Use OfflineDatabase for achievements')
  Future<List<Map<String, dynamic>>> getUserAchievements() async {
    return [];
  }

  @Deprecated('Use OfflineDatabase for weekly activity')
  Future<Map<String, int>> getWeeklyActivity() async {
    return {};
  }
}
