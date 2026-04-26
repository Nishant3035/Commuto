import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Cross-platform location service with proper web support.
///
/// Handles permission flow, HTTPS requirements on web,
/// and provides a fallback to Mumbai if location is unavailable.
class LocationService {
  static StreamSubscription<Position>? _positionSub;

  // Default fallback location (Mumbai)
  static const LatLng defaultLocation = LatLng(19.0760, 72.8777);

  /// Get current location with proper permission handling.
  /// Returns null if location cannot be obtained (shows warning in debug).
  static Future<LatLng?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services disabled');
        return null;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission permanently denied');
        return null;
      }

      // Get position with appropriate timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: kIsWeb ? 15 : 10),
        ),
      );

      debugPrint('📍 Location: ${position.latitude}, ${position.longitude}');
      return LatLng(position.latitude, position.longitude);
    } on TimeoutException {
      debugPrint('⚠️ Location request timed out');
      return null;
    } on LocationServiceDisabledException {
      debugPrint('⚠️ Location service disabled');
      return null;
    } catch (e) {
      debugPrint('⚠️ Location error: $e');
      return null;
    }
  }

  /// Get current location with fallback to default (Mumbai).
  /// Always returns a valid LatLng — never null.
  /// Returns a record with the location and whether it's the actual location.
  static Future<({LatLng location, bool isActual})> getCurrentLocationWithFallback() async {
    final loc = await getCurrentLocation();
    if (loc != null) {
      return (location: loc, isActual: true);
    }
    debugPrint('ℹ️ Using fallback location (Mumbai)');
    return (location: defaultLocation, isActual: false);
  }

  /// Ensure location permissions are granted.
  /// Returns true if permission is available, false otherwise.
  static Future<bool> ensurePermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('⚠️ Permission check error: $e');
      return false;
    }
  }

  /// Start continuous location tracking.
  /// Returns a stream of LatLng positions.
  static Stream<LatLng> startTracking({int distanceFilter = 10}) {
    final controller = StreamController<LatLng>();

    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    ).listen(
      (position) {
        controller.add(LatLng(position.latitude, position.longitude));
      },
      onError: (e) {
        debugPrint('⚠️ Location tracking error: $e');
      },
    );

    return controller.stream;
  }

  /// Stop continuous location tracking.
  static void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  /// Calculate distance in km between two LatLng points.
  static double distanceBetween(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
      a.latitude, a.longitude,
      b.latitude, b.longitude,
    ) / 1000; // Convert meters to km
  }
}
