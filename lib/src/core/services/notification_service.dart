import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static const String _paymentChannelId = 'payment_channel';
  static const String _contentChannelId = 'content_channel';
  static const String _generalChannelId = 'general_channel';

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createNotificationChannels();
    await _firebaseMessaging.requestPermission();

    final token = await _firebaseMessaging.getToken();
    debugPrint('FCM token available: ${token != null}');

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);
  }

  Future<void> _createNotificationChannels() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    const paymentChannel = AndroidNotificationChannel(
      _paymentChannelId,
      'Payment Notifications',
      description: 'Notifications about payment approval and rejection',
      importance: Importance.high,
      enableLights: true,
      enableVibration: true,
      ledColor: Colors.green,
    );
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(paymentChannel);

    const contentChannel = AndroidNotificationChannel(
      _contentChannelId,
      'Content Notifications',
      description: 'Notifications about new content and updates',
      importance: Importance.defaultImportance,
      enableLights: true,
    );
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(contentChannel);

    const generalChannel = AndroidNotificationChannel(
      _generalChannelId,
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.low,
    );
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }

  Future<void> showPaymentNotification({
    required String title,
    required String body,
    required bool isApproved,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _paymentChannelId,
      'Payment Notifications',
      channelDescription: 'Notifications about payment approval and rejection',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.green,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  Future<void> showContentNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _contentChannelId,
      'Content Notifications',
      channelDescription: 'Notifications about new content and updates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  Future<void> showGeneralNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _generalChannelId,
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.low,
      priority: Priority.low,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final type = (message.data['type'] as String? ?? '').toLowerCase();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Payment notifications are private: fail closed if the recipient
    // is missing, no user is signed in, or the recipient does not match.
    if (type == 'payment') {
      final targetUserId =
          (message.data['target_user_id'] as String? ?? '').trim();
      if (currentUserId == null ||
          targetUserId.isEmpty ||
          targetUserId != currentUserId) {
        debugPrint(
          'NotificationService: suppressed payment notification; '
          'recipient could not be verified.',
        );
        return;
      }
    }

    final title = message.notification?.title ?? 'ACADIA';
    final body =
        message.notification?.body ?? 'You have a new notification';
    final status = (message.data['status'] as String? ?? '').toLowerCase();

    switch (type) {
      case 'payment':
        showPaymentNotification(
          title: title,
          body: body,
          isApproved: status == 'approved',
        );
        break;
      case 'content':
        showContentNotification(title: title, body: body);
        break;
      default:
        showGeneralNotification(title: title, body: body);
        break;
    }
  }

  void _handleMessageOpen(RemoteMessage message) {
    final type = (message.data['type'] as String? ?? '').toLowerCase();

    if (type == 'payment') {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final targetUserId =
          (message.data['target_user_id'] as String? ?? '').trim();

      if (currentUserId == null ||
          targetUserId.isEmpty ||
          targetUserId != currentUserId) {
        debugPrint(
          'NotificationService: ignored payment tap; '
          'recipient could not be verified.',
        );
        return;
      }
      flutterGlobalKey.currentState?.pushNamed('/payment-history');
    } else if (type == 'content') {
      flutterGlobalKey.currentState?.pushNamed('/subjects');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }
}

final GlobalKey<NavigatorState> flutterGlobalKey =
    GlobalKey<NavigatorState>();
