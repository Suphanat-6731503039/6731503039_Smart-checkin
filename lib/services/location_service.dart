import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // ──────────────────────────────────────────────────────────
  //  Core: get current position
  // ──────────────────────────────────────────────────────────
  static Future<Position> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permission permanently denied. Please enable it in Settings.');
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ──────────────────────────────────────────────────────────
  //  GPS classroom validation
  // ──────────────────────────────────────────────────────────

  /// Returns distance in meters between two coordinates (Haversine formula)
  static double distanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const R = 6371000.0; // Earth radius in metres
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  /// Validate that the current device is inside the classroom radius.
  /// Returns a [GpsValidationResult] with distance and whether it passed.
  static Future<GpsValidationResult> validateInClassroom({
    required double classroomLat,
    required double classroomLon,
    int radiusMeters = 100,
  }) async {
    final pos = await getLocation();
    final distance = distanceMeters(
      lat1: pos.latitude,
      lon1: pos.longitude,
      lat2: classroomLat,
      lon2: classroomLon,
    );
    return GpsValidationResult(
      position: pos,
      distanceMeters: distance,
      radiusMeters: radiusMeters,
      isInside: distance <= radiusMeters,
    );
  }
}

class GpsValidationResult {
  final Position position;
  final double distanceMeters;
  final int radiusMeters;
  final bool isInside;

  const GpsValidationResult({
    required this.position,
    required this.distanceMeters,
    required this.radiusMeters,
    required this.isInside,
  });
}
