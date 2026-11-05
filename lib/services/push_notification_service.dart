import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

const String _badgeCountKey = 'unread_notifications_count';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.instance._incrementBadge();
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
  FlutterLocalNotificationsPlugin();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sirafleet_events',
    'Évènements SiraFleet',
    description: 'Alertes, missions, messages et maintenance',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> init() async {
    debugPrint('=== PUSH INIT : démarrage ===');

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('=== PUSH INIT : permission = ${settings.authorizationStatus} ===');

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('=== PUSH REÇU (foreground) : ${message.notification?.title} - ${message.notification?.body} ===');
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNavigation);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(initialMessage);
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final count = await _getBadgeCount();
    if (count > 0) {
      await _applyBadge(count);
    }

    debugPrint('=== PUSH INIT : terminé ===');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final newCount = await _incrementBadge();

    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          number: newCount,
        ),
        iOS: DarwinNotificationDetails(badgeNumber: newCount),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;
    final data = jsonDecode(response.payload!) as Map<String, dynamic>;
    _navigateFromData(data);
  }

  void _handleNavigation(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type'];
    final id = data['id'];
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    switch (type) {
      case 'sos':
      case 'alerte':
        nav.pushNamed('/signalement-detail', arguments: id);
        break;
      case 'mission':
        nav.pushNamed('/mission-detail', arguments: id);
        break;
      case 'message':
        nav.pushNamed('/signalement-chat', arguments: id);
        break;
      case 'maintenance':
        nav.pushNamed('/maintenance-detail', arguments: id);
        break;
    }

    clearBadge();
  }

  // ============================================================
  // GESTION DU COMPTEUR DE BADGE
  // ============================================================

  Future<int> _getBadgeCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_badgeCountKey) ?? 0;
  }

  Future<int> _incrementBadge() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_badgeCountKey) ?? 0) + 1;
    await prefs.setInt(_badgeCountKey, count);
    await _applyBadge(count);
    return count;
  }

  Future<void> _applyBadge(int count) async {
    if (kIsWeb) return;
    try {
      final supported = await AppBadgePlus.isSupported();
      if (supported) {
        await AppBadgePlus.updateBadge(count);
      }
    } catch (_) {}
  }

  Future<void> clearBadge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_badgeCountKey, 0);
    if (!kIsWeb) {
      try {
        await AppBadgePlus.updateBadge(0);
      } catch (_) {}
    }
  }

  // ============================================================
  // ENREGISTREMENT / SUPPRESSION DU TOKEN CÔTÉ SERVEUR
  // ============================================================

  Future<void> registerToken(String authToken) async {
    debugPrint('=== REGISTER TOKEN : appelé avec authToken = $authToken ===');

    final fcmToken = kIsWeb
        ? await _messaging.getToken(
      vapidKey:
      'BLcvUvVm9G1oV8JtW7SOruQIqai-Cyj01X8LPCZI-Mo-nzyPHmrEKXDgHtEgE8SiTzQWQl3FuPq_9GE3w3snaTI',
    )
        : await _messaging.getToken();

    debugPrint('=== FCM TOKEN OBTENU : $fcmToken ===');

    if (fcmToken == null) {
      debugPrint('=== FCM TOKEN EST NULL, ARRÊT ===');
      return;
    }

    await _sendTokenToServer(authToken, fcmToken);

    _messaging.onTokenRefresh.listen((t) => _sendTokenToServer(authToken, t));
  }

  Future<void> _sendTokenToServer(String authToken, String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/fcm-token'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );
      debugPrint('=== ENVOI TOKEN AU SERVEUR : ${response.statusCode} - ${response.body} ===');
    } catch (e) {
      debugPrint('=== ERREUR ENVOI TOKEN : $e ===');
    }
  }

  Future<void> unregisterToken(String authToken) async {
    try {
      await http.delete(
        Uri.parse('${AppConstants.baseUrl}/fcm-token'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
    } catch (_) {}
    await _messaging.deleteToken();
    await clearBadge();
  }
}