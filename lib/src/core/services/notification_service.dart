import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:acadia/src/core/constants/colors.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Notification channels
  static const String _paymentChannelId = 'payment_channel';
  static const String _contentChannelId = 'content_channel';
  static const String _generalChannelId = 'general_channel';

  Future<void> initialize() async {
    // Initialize Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channels
    await _createNotificationChannels();

    // Request permissions
    await _firebaseMessaging.requestPermission();

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $token');

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);
  }

  Future<void> _createNotificationChannels() async {
    if (Theme.of(flutterGlobalKey.currentContext!).platform == TargetPlatform.android) {
      // Payment channel
      const AndroidNotificationChannel paymentChannel = AndroidNotificationChannel(
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

      // Content channel
      const AndroidNotificationChannel contentChannel = AndroidNotificationChannel(
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

      // General channel
      const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
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
  }

  Future<void> showPaymentNotification({
    required String title,
    required String body,
    required bool isApproved,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _paymentChannelId,
      'Payment Notifications',
      channelDescription: 'Notifications about payment approval and rejection',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.green,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
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
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _contentChannelId,
      'Content Notifications',
      channelDescription: 'Notifications about new content and updates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
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
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _generalChannelId,
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.low,
      priority: Priority.low,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'ACADIA';
    final body = message.notification?.body ?? 'You have a new notification';
    
    showGeneralNotification(title: title, body: body);
  }

  void _handleMessageOpen(RemoteMessage message) {
    // Handle navigation based on notification type
    final type = message.data['type'];
    if (type == 'payment') {
      // Navigate to payment history
      flutterGlobalKey.currentState?.pushNamed('/payment-history');
    } else if (type == 'content') {
      // Navigate to content
      flutterGlobalKey.currentState?.pushNamed('/subjects');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap when app is in background
    debugPrint('Notification tapped: ${response.payload}');
  }
}

// Global key for navigation
final GlobalKey<NavigatorState> flutterGlobalKey = GlobalKey<NavigatorState>();