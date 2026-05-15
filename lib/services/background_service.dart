import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_entry.dart';
import 'notification_service.dart';

class _Keys {
  static const String history = 'lt_history';
  static const String isTracking = 'lt_is_tracking';
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((_) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((_) async {
    await NotificationService.cancelTrackingNotification();
    await service.stopSelf();
  });

  await _recordAndBroadcast(service);

  Timer.periodic(const Duration(seconds: 60), (_) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_Keys.isTracking) ?? false)) {
      await service.stopSelf();
      return;
    }
    await _recordAndBroadcast(service);
  });
}

Future<void> _recordAndBroadcast(ServiceInstance service) async {
  try {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    final entry = LocationEntry(
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
      altitude: pos.altitude,
      speed: pos.speed,
      heading: pos.heading,
      timestamp: pos.timestamp,
      source: 'background',
    );

    await _appendToHistory(entry);

    final formatted =
        DateFormat('dd MMM HH:mm:ss').format(entry.timestamp.toLocal());
    await NotificationService.showTrackingNotification(
      latitude: entry.latitude,
      longitude: entry.longitude,
      timestamp: formatted,
    );

    service.invoke('locationUpdate', entry.toJson());
  } catch (_) {
  }
}

Future<void> _appendToHistory(LocationEntry entry) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_Keys.history);
  final history =
      raw != null ? LocationEntry.decodeList(raw) : <LocationEntry>[];

  history.add(entry);
  if (history.length > 100) {
    history.removeRange(0, history.length - 100);
  }

  await prefs.setString(_Keys.history, LocationEntry.encodeList(history));
}

class BackgroundLocationService {
  BackgroundLocationService._();

  static final _svc = FlutterBackgroundService();

  static Future<void> initialize() async {
    await _svc.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: NotificationService.kTrackingChannelId,
        initialNotificationTitle: '📍 Location Tracker',
        initialNotificationContent: 'Initialising…',
        foregroundServiceNotificationId: NotificationService.kTrackingNotifId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_Keys.isTracking, true);
    await _svc.startService();
  }

  static Future<void> stop() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_Keys.isTracking, false);
    _svc.invoke('stopService');
    await NotificationService.cancelTrackingNotification();
  }

  static Future<bool> isRunning() => _svc.isRunning();

  static Future<List<LocationEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_Keys.history);
    if (raw == null || raw.isEmpty) return [];
    return LocationEntry.decodeList(raw);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_Keys.history);
  }

  static Stream<Map<String, dynamic>?> get locationStream =>
      _svc.on('locationUpdate');
}
