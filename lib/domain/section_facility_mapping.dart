import 'facility_capacity_model.dart';
import 'stadium_layout.dart';
import 'pathfinder.dart';

/// Precomputed nearest facilities per section.
///
/// This avoids repeated pathfinding calls by storing sorted lists
/// of facilities for each seating section.
class SectionFacilityMapping {
  SectionFacilityMapping._();

  /// Nearest food facilities per section (sorted by base distance).
  static final Map<String, List<String>> _nearestFood = {};

  /// Nearest restroom facilities per section (sorted by base distance).
  static final Map<String, List<String>> _nearestRestroom = {};

  /// Whether mappings have been computed.
  static bool _computed = false;

  /// Precompute nearest facilities for all sections.
  /// Should be called once at app initialization.
  static void precompute() {
    if (_computed) return;
    _computed = true;

    // Ensure stadium layout is built
    StadiumLayout.buildOnce();

    // Sections to compute for
    const sections = ['vip', 'standard'];

    // Food facilities
    final foodFacilities = ['food1', 'food2', 'food3', 'foodCourt'];

    // Restroom facilities
    final restroomFacilities = ['wc1', 'wc2', 'wc3', 'restroom'];

    for (final sectionId in sections) {
      _nearestFood[sectionId] = _sortByDistance(sectionId, foodFacilities);
      _nearestRestroom[sectionId] =
          _sortByDistance(sectionId, restroomFacilities);
    }

    // Also compute for ring nodes (users might be anywhere)
    const ringNodes = ['ringN', 'ringE', 'ringS', 'ringW', 'concourseMain'];
    for (final nodeId in ringNodes) {
      _nearestFood[nodeId] = _sortByDistance(nodeId, foodFacilities);
      _nearestRestroom[nodeId] = _sortByDistance(nodeId, restroomFacilities);
    }

    // And for gates
    const gates = ['gateA', 'gateB', 'gateC', 'gateD'];
    for (final gateId in gates) {
      _nearestFood[gateId] = _sortByDistance(gateId, foodFacilities);
      _nearestRestroom[gateId] = _sortByDistance(gateId, restroomFacilities);
    }
  }

  /// Sort facilities by path cost from a given node.
  static List<String> _sortByDistance(
      String fromNodeId, List<String> facilityIds) {
    final startNode = StadiumLayout.nodesById[fromNodeId];
    if (startNode == null) return facilityIds;

    final distances = <String, int>{};

    for (final facilityId in facilityIds) {
      final endNode = StadiumLayout.nodesById[facilityId];
      if (endNode == null) continue;

      final path = Pathfinder.findPath(
        graph: StadiumLayout.graph,
        start: startNode,
        end: endNode,
        useCongestion: false, // Use base distances
      );

      if (path.isNotEmpty) {
        distances[facilityId] = _calculatePathCost(path);
      }
    }

    // Sort by distance
    final sorted = facilityIds.toList()
      ..sort((a, b) {
        final distA = distances[a] ?? 999;
        final distB = distances[b] ?? 999;
        return distA.compareTo(distB);
      });

    return sorted;
  }

  /// Calculate total path cost.
  static int _calculatePathCost(List<dynamic> path) {
    if (path.length < 2) return 0;
    int total = 0;

    for (int i = 0; i < path.length - 1; i++) {
      final edge = StadiumLayout.graph.edges[path[i]]?[path[i + 1]];
      if (edge != null) {
        total += edge;
      }
    }

    return total;
  }

  /// Get nearest facilities of a type for a section.
  static List<String> getNearestFacilities(
      String sectionId, FacilityType type) {
    if (!_computed) precompute();

    switch (type) {
      case FacilityType.food:
        return _nearestFood[sectionId] ?? [];
      case FacilityType.restroom:
        return _nearestRestroom[sectionId] ?? [];
    }
  }

  /// Get the first available facility (respecting capacity).
  static String? getFirstAvailable(String sectionId, FacilityType type) {
    final nearestList = getNearestFacilities(sectionId, type);

    for (final facilityId in nearestList) {
      final facility = FacilityCapacityModel.getFacility(facilityId);
      if (facility != null && !facility.isFull) {
        return facilityId;
      }
    }

    // All full, return first anyway
    return nearestList.isNotEmpty ? nearestList.first : null;
  }

  /// Reset computed mappings (for testing or when graph changes).
  static void reset() {
    _nearestFood.clear();
    _nearestRestroom.clear();
    _computed = false;
  }
}
