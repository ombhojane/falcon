import 'dart:async';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../models/alert_model.dart';
import '../models/crypto_model.dart';
import 'crypto_service.dart';

class AlertService {
  final List<PriceAlert> _alerts = [];
  final CryptoService _cryptoService = CryptoService();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final _alertsController = StreamController<List<PriceAlert>>.broadcast();

  static const backgroundTaskName = 'priceAlertChecker';

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
    // Store alerts in shared preferences for background access
    _saveAlerts();
  }

  void removeAlert(PriceAlert alert) {
    _alerts.remove(alert);
    _alertsController.add(_alerts);
    _saveAlerts();
  }

  Future<void> _saveAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final alertsJson = _alerts.map((alert) => {
      'cryptoId': alert.cryptoId,
      'targetPrice': alert.targetPrice,
      'isGreaterThan': alert.isGreaterThan,
    }).toList();
    await prefs.setString('price_alerts', json.encode(alertsJson));
  }

  Future<List<PriceAlert>> _loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final alertsJson = prefs.getString('price_alerts');
    if (alertsJson == null) return [];

    final List<dynamic> decoded = json.decode(alertsJson);
    return decoded.map((json) => PriceAlert(
      cryptoId: json['cryptoId'],
      targetPrice: json['targetPrice'],
      isGreaterThan: json['isGreaterThan'],
    )).toList();
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
    
    // Initialize Workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    // Register periodic task
    await Workmanager().registerPeriodicTask(
      'priceAlerts',
      backgroundTaskName,
      frequency: const Duration(minutes: 15), // Minimum interval allowed
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  @override
  void dispose() {
    _alertsController.close();
  }
}

// This needs to be a top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case AlertService.backgroundTaskName:
        final alerts = await AlertService()._loadAlerts();
        final cryptoService = CryptoService();
        
        for (final alert in alerts) {
          try {
            final crypto = await cryptoService.getCryptoById(alert.cryptoId);
            if (crypto != null) {
              if ((alert.isGreaterThan && crypto.currentPrice >= alert.targetPrice) ||
                  (!alert.isGreaterThan && crypto.currentPrice <= alert.targetPrice)) {
                // Show notification
                final notifications = FlutterLocalNotificationsPlugin();
                const androidDetails = AndroidNotificationDetails(
                  'price_alerts',
                  'Price Alerts',
                  channelDescription: 'Notifications for price alerts',
                  importance: Importance.max,
                  priority: Priority.high,
                );
                const notificationDetails = NotificationDetails(android: androidDetails);
                
                await notifications.show(
                  DateTime.now().millisecond,
                  'Price Alert',
                  '${crypto.name} has ${alert.isGreaterThan ? 'reached' : 'fallen to'} \$${alert.targetPrice.toStringAsFixed(2)}',
                  notificationDetails,
                );
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error checking price alert: $e');
            }
          }
        }
        break;
    }
    return true;
  });
}
