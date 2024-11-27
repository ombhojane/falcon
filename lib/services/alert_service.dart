import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alert_model.dart';
import '../models/crypto_model.dart';
import 'crypto_service.dart';

class AlertService {
  final List<PriceAlert> _alerts = [];
  final CryptoService _cryptoService = CryptoService();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final _alertsController = StreamController<List<PriceAlert>>.broadcast();

  Stream<List<PriceAlert>> get alertsStream => _alertsController.stream;

  AlertService() {
    _initializeNotifications();
    _startMonitoring();
  }

  Future<void> _initializeNotifications() async {
    // Initialize settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    // Initialize plugin
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        if (kDebugMode) {
          print('Notification tapped: ${response.payload}');
        }
      },
    );

    // Request Android permissions
    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  void addAlert(PriceAlert alert) {
    _alerts.add(alert);
    _alertsController.add(_alerts);
  }

  void removeAlert(PriceAlert alert) {
    _alerts.remove(alert);
    _alertsController.add(_alerts);
  }

  Future<void> _startMonitoring() async {
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      for (var alert in _alerts) {
        final crypto = await _cryptoService.getCryptoById(alert.cryptoId);
        if (crypto != null && 
            ((alert.isGreaterThan && crypto.currentPrice >= alert.targetPrice) ||
            (!alert.isGreaterThan && crypto.currentPrice <= alert.targetPrice))) {
          _showNotification(crypto, alert);
          removeAlert(alert);
        }
      }
    });
  }

  Future<void> _showNotification(CryptoCurrency crypto, PriceAlert alert) async {
    const androidDetails = AndroidNotificationDetails(
      'price_alerts',
      'Price Alerts',
      channelDescription: 'Notifications for price alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      enableLights: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      'Price Alert',
      '${crypto.name} has ${alert.isGreaterThan ? 'reached' : 'fallen to'} your target price of \$${alert.targetPrice.toStringAsFixed(2)}',
      notificationDetails,
    );
  }

  Future<void> showTestNotification(String cryptoName, double price) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'price_alerts',
        'Price Alerts',
        channelDescription: 'Test notifications for price alerts',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        enableLights: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecond,
        'Price Update',
        '$cryptoName current price: \$${price.toStringAsFixed(2)}',
        notificationDetails,
      );
      if (kDebugMode) {
        print('Notification sent successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error showing notification: $e');
      }
    }
  }

  Future<void> initialize() async {
    await _initializeNotifications();
  }

  @override
  void dispose() {
    _alertsController.close();
  }
}
