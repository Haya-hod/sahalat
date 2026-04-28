import 'dart:math';
import 'package:geolocator/geolocator.dart';

/// Stadium node GPS coordinates
/// All nodes in the stadium graph with their GPS positions
class StadiumNodeCoordinates {
  // Stadium center reference point (adjust to actual stadium location)
  static const double _centerLat = 24.7140;
  static const double _centerLng = 46.6275;
  static const double _scale = 0.0004; // Scale factor for coordinate mapping

  /// GPS coordinates for all stadium nodes
  /// Based on the relative positions in NodeCoordinates (0-100 scale)
  static const Map<String, Map<String, double>> nodes = {
    // Gates (outer perimeter - cardinal directions)
    'gateA': {'lat': 24.7140, 'lng': 46.6255},  // West gate (x:0, y:50)
    'gateB': {'lat': 24.7120, 'lng': 46.6275},  // South gate (x:50, y:100)
    'gateC': {'lat': 24.7140, 'lng': 46.6295},  // East gate (x:100, y:50)
    'gateD': {'lat': 24.7160, 'lng': 46.6275},  // North gate (x:50, y:0)

    // Ring Walkway (outer concourse loop)
    'ringN': {'lat': 24.7154, 'lng': 46.6275},  // North ring (x:50, y:15)
    'ringE': {'lat': 24.7140, 'lng': 46.6289},  // East ring (x:85, y:50)
    'ringS': {'lat': 24.7126, 'lng': 46.6275},  // South ring (x:50, y:85)
    'ringW': {'lat': 24.7140, 'lng': 46.6261},  // West ring (x:15, y:50)

    // Concourse (center hub)
    'concourseMain': {'lat': 24.7140, 'lng': 46.6275},  // Center (x:50, y:50)

    // Sections (inner ring, close to center)
    'vip': {'lat': 24.7146, 'lng': 46.6275},       // VIP section (x:50, y:35)
    'standard': {'lat': 24.7134, 'lng': 46.6275},  // Standard section (x:50, y:65)

    // Legacy POIs
    'restroom': {'lat': 24.7140, 'lng': 46.6267},  // West of concourse (x:30, y:50)
    'foodCourt': {'lat': 24.7140, 'lng': 46.6283}, // East of concourse (x:70, y:50)

    // Phase 5: Multiple Facilities (distributed around stadium)
    'food1': {'lat': 24.7152, 'lng': 46.6267},  // Near North ring (x:40, y:20)
    'food2': {'lat': 24.7144, 'lng': 46.6287},  // Near East ring (x:80, y:40)
    'food3': {'lat': 24.7128, 'lng': 46.6275},  // Near South ring (x:50, y:80)
    'wc1': {'lat': 24.7144, 'lng': 46.6263},    // Near West ring (x:20, y:40)
    'wc2': {'lat': 24.7152, 'lng': 46.6279},    // Between North/East (x:60, y:20)
    'wc3': {'lat': 24.7128, 'lng': 46.6269},    // Near South/West (x:35, y:80)
  };

  /// Labels for all nodes
  static const Map<String, String> nodeLabels = {
    'gateA': 'Gate A',
    'gateB': 'Gate B',
    'gateC': 'Gate C',
    'gateD': 'Gate D',
    'ringN': 'North Ring',
    'ringE': 'East Ring',
    'ringS': 'South Ring',
    'ringW': 'West Ring',
    'concourseMain': 'Main Concourse',
    'vip': 'VIP Section',
    'standard': 'Standard Section',
    'restroom': 'Restrooms',
    'foodCourt': 'Food Court',
    'food1': 'Food Court 1',
    'food2': 'Food Court 2',
    'food3': 'Food Court 3',
    'wc1': 'Restroom 1',
    'wc2': 'Restroom 2',
    'wc3': 'Restroom 3',
  };

  /// Get only gate coordinates (for backward compatibility)
  static Map<String, Map<String, double>> get gates => {
    'gateA': nodes['gateA']!,
    'gateB': nodes['gateB']!,
    'gateC': nodes['gateC']!,
    'gateD': nodes['gateD']!,
  };

  static Map<String, String> get gateLabels => {
    'gateA': 'Gate A',
    'gateB': 'Gate B',
    'gateC': 'Gate C',
    'gateD': 'Gate D',
  };
}

/// Backward compatibility alias
typedef StadiumGateCoordinates = StadiumNodeCoordinates;

class LocationService {
  /// Check if location services are enabled and permission is granted
  static Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current GPS position
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        print('[LocationService] No permission');
        return null;
      }

      // Try to get last known position first (faster)
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        print('[LocationService] Using last known position: ${lastKnown.latitude}, ${lastKnown.longitude}');
        return lastKnown;
      }

      // Otherwise get current position with longer timeout
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 30),
        ),
      );
    } catch (e) {
      print('[LocationService] Error getting position: $e');
      return null;
    }
  }

  /// Calculate distance between two points using Haversine formula
  static double _calculateDistance(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    const double earthRadius = 6371000; // meters

    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Find the nearest gate to the current position
  static Future<NearestGateResult?> findNearestGate() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    String? nearestGateId;
    double minDistance = double.infinity;

    for (final entry in StadiumNodeCoordinates.gates.entries) {
      final gateLat = entry.value['lat']!;
      final gateLng = entry.value['lng']!;

      final distance = _calculateDistance(
        position.latitude, position.longitude,
        gateLat, gateLng,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestGateId = entry.key;
      }
    }

    if (nearestGateId == null) return null;

    return NearestGateResult(
      gateId: nearestGateId,
      gateLabel: StadiumNodeCoordinates.gateLabels[nearestGateId] ?? nearestGateId,
      distanceMeters: minDistance,
      userLat: position.latitude,
      userLng: position.longitude,
    );
  }

  /// Find the nearest stadium node to the current position (any node, not just gates)
  static Future<NearestNodeResult?> findNearestNode() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    String? nearestNodeId;
    double minDistance = double.infinity;

    for (final entry in StadiumNodeCoordinates.nodes.entries) {
      final nodeLat = entry.value['lat']!;
      final nodeLng = entry.value['lng']!;

      final distance = _calculateDistance(
        position.latitude, position.longitude,
        nodeLat, nodeLng,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestNodeId = entry.key;
      }
    }

    if (nearestNodeId == null) return null;

    return NearestNodeResult(
      nodeId: nearestNodeId,
      nodeLabel: StadiumNodeCoordinates.nodeLabels[nearestNodeId] ?? nearestNodeId,
      distanceMeters: minDistance,
      userLat: position.latitude,
      userLng: position.longitude,
    );
  }

  /// Find nearest node from a specific position (without GPS call)
  static NearestNodeResult? findNearestNodeFromPosition(double lat, double lng) {
    String? nearestNodeId;
    double minDistance = double.infinity;

    for (final entry in StadiumNodeCoordinates.nodes.entries) {
      final nodeLat = entry.value['lat']!;
      final nodeLng = entry.value['lng']!;

      final distance = _calculateDistance(lat, lng, nodeLat, nodeLng);

      if (distance < minDistance) {
        minDistance = distance;
        nearestNodeId = entry.key;
      }
    }

    if (nearestNodeId == null) return null;

    return NearestNodeResult(
      nodeId: nearestNodeId,
      nodeLabel: StadiumNodeCoordinates.nodeLabels[nearestNodeId] ?? nearestNodeId,
      distanceMeters: minDistance,
      userLat: lat,
      userLng: lng,
    );
  }
}

class NearestGateResult {
  final String gateId;
  final String gateLabel;
  final double distanceMeters;
  final double userLat;
  final double userLng;

  NearestGateResult({
    required this.gateId,
    required this.gateLabel,
    required this.distanceMeters,
    required this.userLat,
    required this.userLng,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)}m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
    }
  }
}

/// Result of finding nearest stadium node (any node type)
class NearestNodeResult {
  final String nodeId;
  final String nodeLabel;
  final double distanceMeters;
  final double userLat;
  final double userLng;

  NearestNodeResult({
    required this.nodeId,
    required this.nodeLabel,
    required this.distanceMeters,
    required this.userLat,
    required this.userLng,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)}m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Check if user is inside the stadium (within reasonable distance of any node)
  bool get isInsideStadium => distanceMeters < 500; // Within 500m of any node
}
