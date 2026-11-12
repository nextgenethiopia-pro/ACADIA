import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Outcome of trying to register this device to a user account.
class DeviceLockResult {
  const DeviceLockResult({required this.granted, this.deviceName});

  /// True when this device owns (or just claimed) the account registration.
  final bool granted;

  /// Human readable device label, useful for messages and diagnostics.
  final String? deviceName;
}

/// One account = one registered device.
///
/// Enforcement happens against Firestore (the backend) inside a transaction:
/// - The first device to sign in claims `activeDeviceId` on `users/{uid}`.
/// - Any other device is rejected at sign-in while that registration exists.
/// - Signing out releases the registration, so the account can move to a new
///   device afterwards.
/// - Because the claim runs in a Firestore transaction, two simultaneous
///   sign-in attempts cannot both register — only the first commit wins.
///
/// Network failures fail-open: a legitimate user is never locked out because
/// the device could not be verified while offline.
class SessionService {
  SessionService._internal();
  static final SessionService instance = SessionService._internal();

  /// SharedPreferences key holding this installation's persistent device id.
  static const String prefDeviceIdKey = 'acadia_device_id';

  static const String deviceLockedMessage =
      'This account is already registered on another device. '
      'Please sign out from that device first, then sign in here again.';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  String? _cachedDeviceId;

  /// Get or generate a persistent device id unique to this app installation.
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(prefDeviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _uuid.v4();
      await prefs.setString(prefDeviceIdKey, deviceId);
    }
    _cachedDeviceId = deviceId;
    return deviceId;
  }

  /// Human readable device name (e.g. "samsung SM-G991B").
  Future<String> getDeviceName() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return '${info.manufacturer} ${info.model}'.trim();
      }
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return info.utsname.machine;
      }
      if (Platform.isWindows) {
        final info = await plugin.windowsInfo;
        return info.productName;
      }
    } catch (e) {
      debugPrint('[SessionService] Unable to read device info: $e');
    }
    return 'Unknown device';
  }

  /// Register this device to [userId] on the backend.
  ///
  /// Returns `granted: false` when the account is already registered to a
  /// different device.
  Future<DeviceLockResult> claimDevice(String userId) async {
    final deviceId = await getDeviceId();
    final deviceName = await getDeviceName();

    try {
      final granted = await _firestore.runTransaction<bool>((transaction) async {
        final ref = _firestore.collection('users').doc(userId);
        final snapshot = await transaction.get(ref);
        final boundDeviceId = snapshot.data()?['activeDeviceId'] as String?;

        // Not registered yet (new or released account): claim it.
        if (boundDeviceId == null || boundDeviceId.isEmpty) {
          transaction.set(
            ref,
            {
              'activeDeviceId': deviceId,
              'activeDeviceName': deviceName,
              'deviceRegisteredAt': FieldValue.serverTimestamp(),
              'lastLoginAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          return true;
        }

        // Same device signing in again: always allowed.
        if (boundDeviceId == deviceId) {
          transaction.set(
            ref,
            {'lastLoginAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true),
          );
          return true;
        }

        // Another device owns the registration: reject.
        return false;
      });

      debugPrint('[SessionService] claimDevice granted=$granted user=$userId');
      return DeviceLockResult(granted: granted, deviceName: deviceName);
    } catch (e) {
      // FAIL-OPEN: never lock out a legitimate user because of a transient
      // network or backend error. Authentication already succeeded.
      debugPrint('[SessionService] claimDevice error (fail-open): $e');
      return DeviceLockResult(granted: true, deviceName: deviceName);
    }
  }

  /// Release the registration on sign-out so the account can be used on
  /// another device. Only clears the binding if this device owns it.
  Future<void> releaseDevice(String userId) async {
    try {
      final deviceId = await getDeviceId();
      final ref = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        final boundDeviceId = snapshot.data()?['activeDeviceId'] as String?;

        if (boundDeviceId != null && boundDeviceId == deviceId) {
          transaction.update(ref, {
            'activeDeviceId': FieldValue.delete(),
            'activeDeviceName': FieldValue.delete(),
          });
        }
      });

      debugPrint('[SessionService] Device registration released for $userId');
    } catch (e) {
      debugPrint('[SessionService] releaseDevice error: $e');
    }
  }

  /// Verify (before the first route is chosen) that this device is still the
  /// registered device for the signed-in account. An account that has never
  /// been bound is bound to this device; a different registered device signs
  /// the stale local session out.
  Future<void> enforceDeviceBindingOnLaunch() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final deviceId = await getDeviceId();
      // Bounded so a slow/offline backend can never block app start-up.
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 4));
      final boundDeviceId = snapshot.data()?['activeDeviceId'] as String?;

      if (boundDeviceId == null || boundDeviceId.isEmpty) {
        // Existing account that has not been bound yet (or a released one).
        await claimDevice(user.uid);
        return;
      }

      if (boundDeviceId != deviceId) {
        debugPrint(
          '[SessionService] Local session is not the registered device. Signing out.',
        );
        await _auth.signOut();
      }
    } catch (e) {
      debugPrint('[SessionService] Launch enforcement skipped (fail-open): $e');
    }
  }
}
