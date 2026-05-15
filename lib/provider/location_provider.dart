import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/location_entry.dart';
import '../services/background_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

enum LocationPermissionState {
  unknown,
  denied,
  foregroundOnly,
  always,
}

class LocationProvider extends ChangeNotifier {

  LocationEntry? _current;
  final List<LocationEntry> _history = [];
  bool _isTracking = false;
  bool _isFetchingFg = false;
  String? _error;
  LocationPermissionState _permState = LocationPermissionState.unknown;

  StreamSubscription<Map<String, dynamic>?>? _bgSub;
  StreamSubscription<Position>? _fgStreamSub;

  LocationEntry? get current => _current;

  List<LocationEntry> get history => List.unmodifiable(_history);

  bool get isTracking => _isTracking;

  bool get isFetchingFg => _isFetchingFg;

  String? get error => _error;

  LocationPermissionState get permissionState => _permState;

  bool get hasAlwaysPermission => _permState == LocationPermissionState.always;

  LocationProvider() {
    _init();
  }

  Future<void> _init() async {
    await _refreshPermState();
    await _loadPersisted();
    _subscribeToBackground();
  }

  Future<void> _refreshPermState() async {
    final perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.always) {
      _permState = LocationPermissionState.always;
    } else if (perm == LocationPermission.whileInUse) {
      _permState = LocationPermissionState.foregroundOnly;
    } else {
      _permState = LocationPermissionState.denied;
    }

    log("Permission (Geolocator): $perm", name: "Location Provider");
    notifyListeners();
  }

  Future<void> _loadPersisted() async {
    final loaded = await BackgroundLocationService.loadHistory();
    _history
      ..clear()
      ..addAll(loaded);

    if (_history.isNotEmpty) _current = _history.last;

    if (Platform.isAndroid) {
      _isTracking = await BackgroundLocationService.isRunning();
    } else {
      _isTracking = false;
    }

    notifyListeners();
  }

  void _subscribeToBackground() {
    if (Platform.isIOS) return;
    _bgSub = BackgroundLocationService.locationStream.listen((data) {
      if (data == null) return;
      final entry = LocationEntry.fromJson(data);
      _addToHistory(entry);
      _current = entry;
      notifyListeners();
    });
  }

  Future<bool> requestPermissions() async {
    final granted = await LocationService.requestAllPermissions();
    await _refreshPermState();
    if (!granted) {
      _error = 'Background location permission is required for tracking. '
          'Please grant "Always" access in Settings.';
      notifyListeners();
    }
    return granted;
  }

  Future<void> refreshLocation() async {
    _isFetchingFg = true;
    _error = null;
    notifyListeners();

    if (!await LocationService.isServiceEnabled()) {
      _error = 'Location services are disabled. Enable GPS in device settings.';
      _isFetchingFg = false;
      notifyListeners();
      return;
    }

    final entry =
        await LocationService.getCurrentPosition(source: 'foreground');

    if (entry == null) {
      _error = 'Could not obtain location. Check permissions and GPS signal.';
    } else {
      _current = entry;
      _addToHistory(entry);
      _error = null;
    }

    _isFetchingFg = false;
    notifyListeners();
  }

  void startLiveStream() {
    _fgStreamSub?.cancel();
    _fgStreamSub = LocationService.positionStream().listen((pos) {
      _current = LocationEntry(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        altitude: pos.altitude,
        speed: pos.speed,
        heading: pos.heading,
        timestamp: pos.timestamp,
        source: 'foreground',
      );
      notifyListeners();
    });
  }

  void stopLiveStream() {
    _fgStreamSub?.cancel();
    _fgStreamSub = null;
  }

  Future<void> toggleTracking() async {
    _error = null;

    if (_isTracking) {
      if (Platform.isAndroid) {
        await BackgroundLocationService.stop();
      } else {
        _stopIOSBackgroundTracking();
      }

      _isTracking = false;
      notifyListeners();
    } else {

      if (Platform.isAndroid) {
        final notifStatus = await Permission.notification.status;
        log("Notification status: $notifStatus", name: "Location Provider");

        if (notifStatus.isDenied) {
          final res = await Permission.notification.request();
          log("Notification request result: $res", name: "Location Provider");
        }
      }

      if (!hasAlwaysPermission) {
        final granted = await requestPermissions();

        if (Platform.isAndroid && !granted) {
          log("Permission NOT granted (Android)", name: "Location Provider");
          return;
        }

        if (Platform.isIOS && !granted) {
          log("iOS: proceeding without Always permission", name: "Location Provider");
        }
      }

      if (Platform.isAndroid) {
        await BackgroundLocationService.start();
      } else {
        final entry = _current;

        await NotificationService.showTrackingNotification(
          latitude: entry?.latitude ?? 0,
          longitude: entry?.longitude ?? 0,
          timestamp: DateTime.now().toString(),
        );
        _startIOSBackgroundTracking();
      }

      _isTracking = true;
      notifyListeners();
    }
  }

  void _startIOSBackgroundTracking() {
    log("iOS tracking STARTED", name: "Location Provider");
    _fgStreamSub?.cancel();

    _fgStreamSub = LocationService.positionStream().listen(
      (pos) {
        log("iOS STREAM FIRED", name: "Location Provider");
        log("Lat: ${pos.latitude}, Lng: ${pos.longitude}", name: "Location Provider");
        log("Accuracy: ${pos.accuracy}, Speed: ${pos.speed}", name: "Location Provider");
        log("Timestamp: ${pos.timestamp}", name: "Location Provider");
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

        _current = entry;
        _addToHistory(entry);
        notifyListeners();
      },
      onError: (e) {
        log("iOS location error: $e", name: "Location Provider");
      },
      cancelOnError: false,
    );
  }

  void _stopIOSBackgroundTracking() {
    _fgStreamSub?.cancel();
    _fgStreamSub = null;
  }

  Future<void> clearHistory() async {
    await BackgroundLocationService.clearHistory();
    _history.clear();
    notifyListeners();
  }

  void _addToHistory(LocationEntry entry) {
    _history.add(entry);
    if (_history.length > 100) {
      _history.removeRange(0, _history.length - 100);
    }
  }

  @override
  void dispose() {
    _bgSub?.cancel();
    _fgStreamSub?.cancel();
    super.dispose();
  }
}
