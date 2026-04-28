/// Congestion levels for stadium zones/edges.
enum CongestionLevel {
  low,
  medium,
  high,
}

/// Extension for congestion level penalties.
extension CongestionLevelExtension on CongestionLevel {
  /// Returns the penalty weight for this congestion level.
  int get penalty {
    switch (this) {
      case CongestionLevel.low:
        return 0;
      case CongestionLevel.medium:
        return 3;
      case CongestionLevel.high:
        return 8;
    }
  }

  String get displayName {
    switch (this) {
      case CongestionLevel.low:
        return 'Low';
      case CongestionLevel.medium:
        return 'Medium';
      case CongestionLevel.high:
        return 'High';
    }
  }
}

/// Predefined congestion scenarios for demonstration.
enum CongestionScenario {
  /// All edges have low congestion (baseline).
  allLow,

  /// Concourse edges are highly congested, forcing ring route.
  concourseHigh,

  /// Ring edges are highly congested; hub entry from gates is also penalized
  /// so routing does not default to cutting through the pitch.
  ringHigh,
}

/// Extension for scenario display names.
extension CongestionScenarioExtension on CongestionScenario {
  String get displayName {
    switch (this) {
      case CongestionScenario.allLow:
        return 'Normal (All Low)';
      case CongestionScenario.concourseHigh:
        return 'Concourse Crowded';
      case CongestionScenario.ringHigh:
        return 'Ring Crowded';
    }
  }

  String get description {
    switch (this) {
      case CongestionScenario.allLow:
        return 'Clear paths everywhere';
      case CongestionScenario.concourseHigh:
        return 'Main concourse congested - use ring walkway';
      case CongestionScenario.ringHigh:
        return 'Ring walkway congested (hub entry also penalized)';
    }
  }
}

/// Manages congestion state for stadium edges.
///
/// This is a separate layer from base graph weights, allowing dynamic
/// routing adjustments without modifying the underlying graph structure.
class CongestionModel {
  CongestionModel._();

  /// Current congestion scenario.
  static CongestionScenario _currentScenario = CongestionScenario.allLow;

  /// Gets the current scenario.
  static CongestionScenario get currentScenario => _currentScenario;

  /// Sets the current congestion scenario.
  static void setScenario(CongestionScenario scenario) {
    _currentScenario = scenario;
    _edgeCongestion.clear();
    _applyScenario(scenario);
  }

  /// Edge-specific congestion levels.
  /// Key format: "nodeA->nodeB" (alphabetically sorted for consistency).
  static final Map<String, CongestionLevel> _edgeCongestion = {};

  /// Returns a normalized edge key (alphabetically sorted).
  static String _edgeKey(String nodeA, String nodeB) {
    final sorted = [nodeA, nodeB]..sort();
    return '${sorted[0]}->${sorted[1]}';
  }

  /// Gets the congestion level for an edge.
  static CongestionLevel getCongestion(String nodeA, String nodeB) {
    return _edgeCongestion[_edgeKey(nodeA, nodeB)] ?? CongestionLevel.low;
  }

  /// Sets the congestion level for an edge.
  static void setCongestion(String nodeA, String nodeB, CongestionLevel level) {
    _edgeCongestion[_edgeKey(nodeA, nodeB)] = level;
  }

  /// Calculates the effective weight for an edge.
  /// effectiveWeight = baseWeight + penalty(congestion level)
  static int getEffectiveWeight(String nodeA, String nodeB, int baseWeight) {
    final congestion = getCongestion(nodeA, nodeB);
    return baseWeight + congestion.penalty;
  }

  /// Returns all edges with their current congestion levels.
  static Map<String, CongestionLevel> get allCongestion =>
      Map.unmodifiable(_edgeCongestion);

  /// Checks if an edge is congested (medium or high).
  static bool isEdgeCongested(String nodeA, String nodeB) {
    final level = getCongestion(nodeA, nodeB);
    return level == CongestionLevel.medium || level == CongestionLevel.high;
  }

  /// Applies a predefined scenario.
  static void _applyScenario(CongestionScenario scenario) {
    switch (scenario) {
      case CongestionScenario.allLow:
        // All edges remain at default (low)
        break;

      case CongestionScenario.concourseHigh:
        // All edges touching main concourse — force ring detours when possible
        setCongestion('gateA', 'concourseMain', CongestionLevel.high);
        setCongestion('gateB', 'concourseMain', CongestionLevel.high);
        setCongestion('gateC', 'concourseMain', CongestionLevel.high);
        setCongestion('gateD', 'concourseMain', CongestionLevel.high);
        setCongestion('ringN', 'concourseMain', CongestionLevel.high);
        setCongestion('ringE', 'concourseMain', CongestionLevel.high);
        setCongestion('ringS', 'concourseMain', CongestionLevel.high);
        setCongestion('ringW', 'concourseMain', CongestionLevel.high);
        setCongestion('concourseMain', 'vip', CongestionLevel.high);
        setCongestion('concourseMain', 'standard', CongestionLevel.high);
        setCongestion('concourseMain', 'restroom', CongestionLevel.high);
        setCongestion('concourseMain', 'foodCourt', CongestionLevel.high);
        setCongestion('concourseMain', 'food1', CongestionLevel.high);
        setCongestion('concourseMain', 'food2', CongestionLevel.high);
        setCongestion('concourseMain', 'food3', CongestionLevel.high);
        setCongestion('concourseMain', 'wc1', CongestionLevel.high);
        setCongestion('concourseMain', 'wc2', CongestionLevel.high);
        setCongestion('concourseMain', 'wc3', CongestionLevel.high);
        break;

      case CongestionScenario.ringHigh:
        // Make all ring edges highly congested
        setCongestion('ringN', 'ringE', CongestionLevel.high);
        setCongestion('ringE', 'ringS', CongestionLevel.high);
        setCongestion('ringS', 'ringW', CongestionLevel.high);
        setCongestion('ringW', 'ringN', CongestionLevel.high);
        // Also congest gate-to-ring connections
        setCongestion('gateA', 'ringW', CongestionLevel.high);
        setCongestion('gateB', 'ringS', CongestionLevel.high);
        setCongestion('gateC', 'ringE', CongestionLevel.high);
        setCongestion('gateD', 'ringN', CongestionLevel.high);
        // Penalize gate→hub so "ring crowded" does not make pitch shortcut cheapest
        setCongestion('gateA', 'concourseMain', CongestionLevel.high);
        setCongestion('gateB', 'concourseMain', CongestionLevel.high);
        setCongestion('gateC', 'concourseMain', CongestionLevel.high);
        setCongestion('gateD', 'concourseMain', CongestionLevel.high);
        break;
    }
  }

  /// Resets to default (all low).
  static void reset() {
    _currentScenario = CongestionScenario.allLow;
    _edgeCongestion.clear();
  }
}
