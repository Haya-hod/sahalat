import 'package:geolocator/geolocator.dart';
import 'location_service.dart';

/// Service for saving and retrieving car parking location
class CarLocationService {
  static Position? _savedCarLocation;
  static String? _savedNearGateId;
  static DateTime? _savedAt;

  /// Check if car location is saved
  static bool get hasCarLocation => _savedCarLocation != null;

  /// Get saved car location
  static Position? get carLocation => _savedCarLocation;

  /// Get the gate nearest to saved car
  static String? get nearestGateId => _savedNearGateId;

  /// Get when car was saved
  static DateTime? get savedAt => _savedAt;

  /// Save current location as car location
  static Future<CarSaveResult> saveCarLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        return CarSaveResult(
          success: false,
          message: 'Could not get current location',
        );
      }

      _savedCarLocation = position;
      _savedAt = DateTime.now();

      // Find nearest gate to car location
      final nearestGate = await LocationService.findNearestGate();
      if (nearestGate != null) {
        _savedNearGateId = nearestGate.gateId;
      }

      return CarSaveResult(
        success: true,
        message: 'Car location saved',
        position: position,
        nearestGateId: _savedNearGateId,
      );
    } catch (e) {
      return CarSaveResult(
        success: false,
        message: 'Error saving location: $e',
      );
    }
  }

  /// Clear saved car location
  static void clearCarLocation() {
    _savedCarLocation = null;
    _savedNearGateId = null;
    _savedAt = null;
  }

  /// Get formatted time since car was saved
  static String get timeSinceSaved {
    if (_savedAt == null) return '';
    final diff = DateTime.now().difference(_savedAt!);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

class CarSaveResult {
  final bool success;
  final String message;
  final Position? position;
  final String? nearestGateId;

  CarSaveResult({
    required this.success,
    required this.message,
    this.position,
    this.nearestGateId,
  });
}
