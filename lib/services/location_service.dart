import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../models/location_entry.dart';

class LocationService {
  LocationService._();

  // static const LocationSettings _highAccuracy = LocationSettings(
  //   accuracy: LocationAccuracy.high,
  //   distanceFilter: 0,
  // );

  static Future<bool> requestAllPermissions() async {
    LocationPermission fg = await Geolocator.checkPermission();

    if (fg == LocationPermission.denied) {
      fg = await Geolocator.requestPermission();
    }

    if (fg == LocationPermission.denied ||
        fg == LocationPermission.deniedForever) {
      return false;
    }

    final bg = await ph.Permission.locationAlways.request();
    return bg.isGranted;
  }

  static Future<ph.PermissionStatus> backgroundPermissionStatus() =>
      ph.Permission.locationAlways.status;

  static Future<bool> isServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  static Future<LocationEntry?> getCurrentPosition({
    String source = 'foreground',
  }) async {
    try {
      if (!await isServiceEnabled()) return null;

      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      return LocationEntry(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        altitude: pos.altitude,
        speed: pos.speed,
        heading: pos.heading,
        timestamp: pos.timestamp,
        source: source,
      );
    } catch (_) {
      return null;
    }
  }

  static Stream<Position> positionStream() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
        ),
      );

  static Future<void> openSettings() => ph.openAppSettings();
}
