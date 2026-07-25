import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Firebase Service (Firestore + Auth)
/// Uses external links for all files (Internet Archive, Cloudinary, Google Drive)
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;

  // ============================================
  // GENERIC FIRESTORE OPERATIONS
  // ============================================

  Future<List<Map<String, dynamic>>> getDocuments(
    String collection, {
    Map<String, dynamic>? where,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
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

  Future<Map<String, dynamic>?> getDocument(String collection, String docId) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Error getting document $collection/$docId: $e');
      return null;
    }
  }

  Future<String> addDocument(String collection, Map<String, dynamic> data) async {
    try {
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

  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    try {
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
  // CONTENT MANAGEMENT
  // ============================================

  Future<void> addContent({
    required String type,
    required String grade,
    required String? stream,
    required String subject,
    required String unit,
    required String title,
    required String externalUrl,
    String? description,
    String? thumbnailUrl,
  }) async {
    await _firestore.collection('content').add({
      'type': type,
      'grade': grade,
      'stream': stream ?? 'all',
      'subject': subject,
      'unit': unit,
      'title': title,
      'external_url': externalUrl,
      'thumbnail_url': thumbnailUrl ?? '',
      'description': description ?? '',
      'created_at': FieldValue.serverTimestamp(),
      'created_by': currentUserId,
    });
  }

  Future<List<Map<String, dynamic>>> getContentForUnit({
    required String grade,
    required String? stream,
    required String subject,
    required String unit,
  }) async {
    final query = await _firestore
        .collection('content')
        .where('grade', isEqualTo: grade)
        .where('subject', isEqualTo: subject)
        .where('unit', isEqualTo: unit)
        .get();

    final allContent = query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

    return allContent.where((item) {
      final itemStream = item['stream'] as String?;
      return itemStream == 'all' || itemStream == stream;
    }).toList();
  }

  Future<void> updateContent(String contentId, Map<String, dynamic> data) async {
    await _firestore.collection('content').doc(contentId).update({
      ...data,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteContent(String contentId) async {
    await _firestore.collection('content').doc(contentId).delete();
  }

  // ============================================
  // USER PROGRESS
  // ============================================

  Future<void> saveUnitProgress({
    required String unitName,
    required String subjectId,
    required double progress,
    required bool isCompleted,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('progress')
        .doc(userId)
        .collection('subjects')
        .doc(subjectId)
        .collection('units')
        .doc(unitName)
        .set({
      'progress': progress,
      'is_completed': isCompleted,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getUserProgress() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('progress')
        .doc(userId)
        .collection('subjects')
        .get();

    List<Map<String, dynamic>> allProgress = [];

    for (var subjectDoc in snapshot.docs) {
      final subjectId = subjectDoc.id;
      final unitsSnapshot = await subjectDoc.reference.collection('units').get();

      for (var unitDoc in unitsSnapshot.docs) {
        final data = unitDoc.data();
        allProgress.add({
          'id': unitDoc.id,
          'subject_id': subjectId,
          ...data,
        });
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

    final payments = query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

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

    final allNotifications = query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

    return allNotifications.where((n) {
      final targetUserId = n['target_user_id'] as String?;
      return targetUserId == null || targetUserId == userId;
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

  Future<List<Map<String, dynamic>>> getUserActivity() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('activity')
        .orderBy('created_at', descending: true)
        .limit(50)
        .get();

    return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> logActivity(String action, String details) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('activity')
        .add({
      'action': action,
      'details': details,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getUserAchievements() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .get();

    return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // ============================================
  // REMOTE CONTENT FETCHING
  // ============================================

  Future<dynamic> fetchRemoteJson(String url) async {
    try {
      final directUrl = _getDirectDownloadLink(url);
      final dio = Dio();
      final response = await dio.get(directUrl);

      if (response.data is String) {
        return json.decode(response.data);
      }
      return response.data;
    } catch (e) {
      debugPrint('Error fetching remote JSON: $e');
      return null;
    }
  }

  String _getDirectDownloadLink(String url) {
    if (url.contains('drive.google.com')) {
      final fileId = _getGoogleDriveFileId(url);
      if (fileId != null) {
        return 'https://docs.google.com/uc?id=$fileId&export=download';
      }
    }
    return url;
  }

  String? _getGoogleDriveFileId(String url) {
    if (url.contains('/file/d/')) {
      final startIndex = url.indexOf('/file/d/') + 8;
      final endIndex = url.indexOf('/', startIndex);
      if (endIndex != -1) {
        return url.substring(startIndex, endIndex);
      }
      return url.substring(startIndex);
    }
    if (url.contains('id=')) {
      final startIndex = url.indexOf('id=') + 3;
      final endIndex = url.indexOf('&', startIndex);
      if (endIndex != -1) {
        return url.substring(startIndex, endIndex);
      }
      return url.substring(startIndex);
    }
    return null;
  }

  Future<Map<String, int>> getWeeklyActivity() async {
    try {
      final userId = currentUserId;
      if (userId == null) return {};

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final activitySnapshot = await _firestore
          .collection('user_activity')
          .where('user_id', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: weekAgo)
          .get();

      final Map<String, int> activityData = {};
      for (var doc in activitySnapshot.docs) {
        final data = doc.data();
        final date = data['timestamp'] as DateTime?;
        if (date != null) {
          final dateKey = '${date.year}-${date.month}-${date.day}';
          activityData[dateKey] = (activityData[dateKey] ?? 0) + 1;
        }
      }

      return activityData;
    } catch (e) {
      debugPrint('Error getting weekly activity: $e');
      return {};
    }
  }
}