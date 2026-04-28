/// Facility types for categorization.
enum FacilityType {
  food,
  restroom,
}

/// Extension for facility type display names.
extension FacilityTypeExtension on FacilityType {
  String get displayName {
    switch (this) {
      case FacilityType.food:
        return 'Food Court';
      case FacilityType.restroom:
        return 'Restroom';
    }
  }

  String get icon {
    switch (this) {
      case FacilityType.food:
        return 'restaurant';
      case FacilityType.restroom:
        return 'wc';
    }
  }
}

/// Capacity levels with associated penalties.
enum CapacityLevel {
  low, // <70% -> penalty 0
  medium, // 70-90% -> penalty 3
  high, // >90% -> penalty 10
}

/// Extension for capacity level properties.
extension CapacityLevelExtension on CapacityLevel {
  int get penalty {
    switch (this) {
      case CapacityLevel.low:
        return 0;
      case CapacityLevel.medium:
        return 3;
      case CapacityLevel.high:
        return 10;
    }
  }

  String get displayName {
    switch (this) {
      case CapacityLevel.low:
        return 'Available';
      case CapacityLevel.medium:
        return 'Busy';
      case CapacityLevel.high:
        return 'Full';
    }
  }
}

/// Individual facility capacity information.
class FacilityInfo {
  final String nodeId;
  final FacilityType type;
  final int capacity;
  int currentLoad;

  FacilityInfo({
    required this.nodeId,
    required this.type,
    required this.capacity,
    this.currentLoad = 0,
  });

  /// Load percentage (0.0 to 1.0+).
  double get loadPercentage => capacity > 0 ? currentLoad / capacity : 0.0;

  /// Load percentage as integer (0-100+).
  int get loadPercent => (loadPercentage * 100).round();

  /// Current capacity level based on load.
  CapacityLevel get level {
    final percent = loadPercentage;
    if (percent < 0.7) return CapacityLevel.low;
    if (percent < 0.9) return CapacityLevel.medium;
    return CapacityLevel.high;
  }

  /// Capacity penalty for routing.
  int get penalty => level.penalty;

  /// Whether facility is at or over capacity.
  bool get isFull => loadPercentage >= 1.0;

  /// Whether facility is nearly full (>90%).
  bool get isNearlyFull => loadPercentage >= 0.9;

  /// Display string showing current/max.
  String get statusText => '$currentLoad/$capacity';

  /// Copy with updated load.
  FacilityInfo copyWith({int? currentLoad}) {
    return FacilityInfo(
      nodeId: nodeId,
      type: type,
      capacity: capacity,
      currentLoad: currentLoad ?? this.currentLoad,
    );
  }
}

/// Static singleton managing all facility capacities.
///
/// This follows the CongestionModel pattern - keeping capacity data
/// separate from the graph structure for modularity.
class FacilityCapacityModel {
  FacilityCapacityModel._();

  /// All registered facilities.
  static final Map<String, FacilityInfo> _facilities = {};

  /// Whether model has been initialized.
  static bool _initialized = false;

  /// Initialize all facilities with default capacities.
  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Food courts (capacity 50-80)
    _facilities['food1'] = FacilityInfo(
      nodeId: 'food1',
      type: FacilityType.food,
      capacity: 50,
      currentLoad: 34,
    );
    _facilities['food2'] = FacilityInfo(
      nodeId: 'food2',
      type: FacilityType.food,
      capacity: 60,
      currentLoad: 42,
    );
    _facilities['food3'] = FacilityInfo(
      nodeId: 'food3',
      type: FacilityType.food,
      capacity: 80,
      currentLoad: 55,
    );

    // Restrooms (capacity 30-50)
    _facilities['wc1'] = FacilityInfo(
      nodeId: 'wc1',
      type: FacilityType.restroom,
      capacity: 40,
      currentLoad: 18,
    );
    _facilities['wc2'] = FacilityInfo(
      nodeId: 'wc2',
      type: FacilityType.restroom,
      capacity: 30,
      currentLoad: 12,
    );
    _facilities['wc3'] = FacilityInfo(
      nodeId: 'wc3',
      type: FacilityType.restroom,
      capacity: 50,
      currentLoad: 25,
    );

    // Legacy POIs (for backward compatibility)
    _facilities['foodCourt'] = FacilityInfo(
      nodeId: 'foodCourt',
      type: FacilityType.food,
      capacity: 100,
      currentLoad: 65,
    );
    _facilities['restroom'] = FacilityInfo(
      nodeId: 'restroom',
      type: FacilityType.restroom,
      capacity: 60,
      currentLoad: 28,
    );
  }

  /// Ensure model is initialized.
  static void _ensureInitialized() {
    if (!_initialized) initialize();
  }

  /// Get facility by node ID.
  static FacilityInfo? getFacility(String nodeId) {
    _ensureInitialized();
    return _facilities[nodeId];
  }

  /// Get all facilities of a specific type.
  static List<FacilityInfo> getByType(FacilityType type) {
    _ensureInitialized();
    return _facilities.values.where((f) => f.type == type).toList();
  }

  /// Get all facilities.
  static List<FacilityInfo> get allFacilities {
    _ensureInitialized();
    return _facilities.values.toList();
  }

  /// Get capacity penalty for a node (0 if not a facility).
  static int getCapacityPenalty(String nodeId) {
    final facility = getFacility(nodeId);
    return facility?.penalty ?? 0;
  }

  /// Update load for a facility.
  static void updateLoad(String nodeId, int newLoad) {
    _ensureInitialized();
    final facility = _facilities[nodeId];
    if (facility != null) {
      _facilities[nodeId] = facility.copyWith(currentLoad: newLoad);
    }
  }

  /// Simulate random loads for demo purposes.
  /// Uses deterministic pattern based on scenario for consistency.
  static void simulateLoads(CapacityScenario scenario) {
    _ensureInitialized();

    switch (scenario) {
      case CapacityScenario.normal:
        // Normal distribution (40-70% full)
        updateLoad('food1', 34);
        updateLoad('food2', 42);
        updateLoad('food3', 55);
        updateLoad('wc1', 18);
        updateLoad('wc2', 12);
        updateLoad('wc3', 25);
        updateLoad('foodCourt', 65);
        updateLoad('restroom', 28);
        break;

      case CapacityScenario.food1Full:
        // Food Court 1 is full, others available
        updateLoad('food1', 48); // 96%
        updateLoad('food2', 25); // 42%
        updateLoad('food3', 30); // 38%
        updateLoad('wc1', 18);
        updateLoad('wc2', 12);
        updateLoad('wc3', 25);
        updateLoad('foodCourt', 45);
        updateLoad('restroom', 20);
        break;

      case CapacityScenario.allBusy:
        // All facilities at 75-85%
        updateLoad('food1', 40);
        updateLoad('food2', 48);
        updateLoad('food3', 64);
        updateLoad('wc1', 32);
        updateLoad('wc2', 24);
        updateLoad('wc3', 40);
        updateLoad('foodCourt', 80);
        updateLoad('restroom', 48);
        break;
    }
  }

  /// Reset to initial state.
  static void reset() {
    _facilities.clear();
    _initialized = false;
  }
}

/// Predefined capacity scenarios for demonstration.
enum CapacityScenario {
  normal,
  food1Full,
  allBusy,
}

/// Extension for scenario display.
extension CapacityScenarioExtension on CapacityScenario {
  String get displayName {
    switch (this) {
      case CapacityScenario.normal:
        return 'Normal Load';
      case CapacityScenario.food1Full:
        return 'Food Court 1 Full';
      case CapacityScenario.allBusy:
        return 'All Facilities Busy';
    }
  }

  String get description {
    switch (this) {
      case CapacityScenario.normal:
        return 'All facilities at normal capacity';
      case CapacityScenario.food1Full:
        return 'Food Court 1 is full - try alternatives';
      case CapacityScenario.allBusy:
        return 'High attendance - all facilities busy';
    }
  }
}
