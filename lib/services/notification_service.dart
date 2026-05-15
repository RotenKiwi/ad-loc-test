import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static const int kTrackingNotifId = 888;
  static const int kAlertNotifId = 889;

  static const String kTrackingChannelId = 'lt_tracking';
  static const String kAlertChannelId = 'lt_alerts';

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: false,
          sound: false,
        );

    await _createChannels();
  }

  static Future<void> _createChannels() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        kTrackingChannelId,
        'Location Tracking',
        description: 'Shown while background location tracking is active.',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
    );

    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        kAlertChannelId,
        'Tracking Alerts',
        description: 'Status updates about location tracking.',
        importance: Importance.defaultImportance,
      ),
    );
  }

  static Future<void> showTrackingNotification({
    required double latitude,
    required double longitude,
    required String timestamp,
  }) async {
    final android = AndroidNotificationDetails(
      kTrackingChannelId,
      'Location Tracking',
      channelDescription: 'Active location tracking.',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        'Latitude:  ${latitude.toStringAsFixed(6)}\n'
        'Longitude: ${longitude.toStringAsFixed(6)}\n'
        'Last update: $timestamp',
        summaryText: 'Background tracking active',
      ),
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
      interruptionLevel: InterruptionLevel.passive,
    );

    await _plugin.show(
      kTrackingNotifId,
      '📍 Location Tracker Active',
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
      NotificationDetails(android: android, iOS: ios),
    );
  }

  static Future<void> cancelTrackingNotification() async {
    await _plugin.cancel(kTrackingNotifId);
  }

  static Future<void> showAlert({
    required String title,
    required String body,
  }) async {
    const android = AndroidNotificationDetails(
      kAlertChannelId,
      'Tracking Alerts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails();
    await _plugin.show(
      kAlertNotifId,
      title,
      body,
      const NotificationDetails(android: android, iOS: ios),
    );
  }
}
