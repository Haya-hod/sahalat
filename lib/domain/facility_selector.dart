import 'stadium_layout.dart';
import 'stadium_models.dart';
import 'pathfinder.dart';
import 'congestion_model.dart';
import 'facility_capacity_model.dart';
import '../core/location_service.dart';

/// Result of smart facility selection.
class FacilitySelectionResult {
  /// Recommended facility node ID.
  final String recommendedNodeId;

  /// Total score (lower is better): routeCost + capacityPenalty.
  final int totalScore;

  /// Route cost from A* pathfinding.
  final int routeCost;

  /// Capacity penalty (0, 3, or 10).
  final int capacityPenalty;

  /// Alternative facilities (top 2-3 fallbacks).
  final List<FacilityAlternative> alternatives;

  /// Warning message if primary is full/busy.
  final String? warning;

  /// The computed path to the recommended facility.
  final List<StadiumNode> path;

  FacilitySelectionResult({
    required this.recommendedNodeId,
    required this.totalScore,
    required this.routeCost,
    required this.capacityPenalty,
    required this.alternatives,
    required this.path,
    this.warning,
  });

  /// Get facility info for the recommended facility.
  FacilityInfo? get facilityInfo =>
      FacilityCapacityModel.getFacility(recommendedNodeId);
}

/// Alternative facility with scoring info.
class FacilityAlternative {
  final String nodeId;
  final int totalScore;
  final int routeCost;
  final int capacityPenalty;
  final FacilityInfo? facilityInfo;

  FacilityAlternative({
    required this.nodeId,
    required this.totalScore,
    required this.routeCost,
    required this.capacityPenalty,
    this.facilityInfo,
  });
}

/// Route cache entry.
class _CacheEntry {
  final int cost;
  final List<StadiumNode> path;

  _CacheEntry(this.cost, this.path);
}

/// Smart facility selector with caching.
///
/// Uses scoring: totalScore = routeCost + capacityPenalty
/// to recommend optimal facilities.
class FacilitySelector {
  FacilitySelector._();

  /// Route cost cache.
  /// Key format: "startId:endId:scenarioName"
  static final Map<String, _CacheEntry> _cache = {};

  /// Last congestion scenario (for cache invalidation).
  static CongestionScenario? _lastScenario;

  /// Select the best facility of a given type from starting location.
  static FacilitySelectionResult selectBest({
    required String startNodeId,
    required FacilityType facilityType,
    bool useCongestion = true,
  }) {
    // Ensure models are initialized
    StadiumLayout.buildOnce();
    FacilityCapacityModel.initialize();

    // Check cache validity
    _invalidateCacheIfNeeded();

    // Prefer Phase 5 nodes (food1–3, wc1–3) over legacy `foodCourt` / `restroom`
    // so "Food" recommends the nearest real court (e.g. F1 from Gate A).
    final facilities = _candidatesForSelection(facilityType);

    // Score each facility
    final scored = <_ScoredFacility>[];

    for (final facility in facilities) {
      final result = _scoreFacility(startNodeId, facility, useCongestion);
      if (result != null) {
        scored.add(result);
      }
    }

    // Sort by total score (lower is better), then route length, then id (stable)
    scored.sort((a, b) {
      final byTotal = a.totalScore.compareTo(b.totalScore);
      if (byTotal != 0) return byTotal;
      final byRoute = a.routeCost.compareTo(b.routeCost);
      if (byRoute != 0) return byRoute;
      return a.nodeId.compareTo(b.nodeId);
    });

    if (scored.isEmpty) {
      // Fallback if no facilities found
      return FacilitySelectionResult(
        recommendedNodeId: facilities.isNotEmpty ? facilities.first.nodeId : '',
        totalScore: 999,
        routeCost: 999,
        capacityPenalty: 0,
        alternatives: [],
        path: [],
        warning: 'No facilities available',
      );
    }

    final best = scored.first;

    // Build alternatives list (excluding best, max 3)
    final alternatives = scored.skip(1).take(3).map((s) {
      return FacilityAlternative(
        nodeId: s.nodeId,
        totalScore: s.totalScore,
        routeCost: s.routeCost,
        capacityPenalty: s.capacityPenalty,
        facilityInfo: FacilityCapacityModel.getFacility(s.nodeId),
      );
    }).toList();

    // Generate warning if best is busy/full
    String? warning;
    if (best.capacityPenalty >= 10) {
      warning = '${StadiumLayout.labelOf(best.nodeId)} is full. Consider alternatives.';
    } else if (best.capacityPenalty >= 3) {
      warning = '${StadiumLayout.labelOf(best.nodeId)} is busy.';
    }

    return FacilitySelectionResult(
      recommendedNodeId: best.nodeId,
      totalScore: best.totalScore,
      routeCost: best.routeCost,
      capacityPenalty: best.capacityPenalty,
      alternatives: alternatives,
      path: best.path,
      warning: warning,
    );
  }

  /// Facilities considered for smart routing (excludes legacy POIs when modern ones exist).
  static List<FacilityInfo> _candidatesForSelection(FacilityType facilityType) {
    final all = FacilityCapacityModel.getByType(facilityType);
    switch (facilityType) {
      case FacilityType.food:
        final numbered =
            all.where((f) => RegExp(r'^food[0-9]+$').hasMatch(f.nodeId)).toList();
        return numbered.isNotEmpty ? numbered : all;
      case FacilityType.restroom:
        final numbered =
            all.where((f) => RegExp(r'^wc[0-9]+$').hasMatch(f.nodeId)).toList();
        return numbered.isNotEmpty ? numbered : all;
    }
  }

  /// Score a single facility.
  static _ScoredFacility? _scoreFacility(
    String startNodeId,
    FacilityInfo facility,
    bool useCongestion,
  ) {
    final startNode = StadiumLayout.nodesById[startNodeId];
    final endNode = StadiumLayout.nodesById[facility.nodeId];

    if (startNode == null || endNode == null) return null;

    // Check cache
    final cacheKey = _getCacheKey(startNodeId, facility.nodeId);
    _CacheEntry? cached = _cache[cacheKey];

    List<StadiumNode> path;
    int routeCost;

    if (cached != null &&
        cached.path.isNotEmpty &&
        cached.cost < 0x3fffffff) {
      path = cached.path;
      routeCost = cached.cost;
    } else {
      // Compute path
      path = Pathfinder.findPath(
        graph: StadiumLayout.graph,
        start: startNode,
        end: endNode,
        useCongestion: useCongestion,
      );

      if (path.isEmpty) return null;

      routeCost = _calculatePathCost(path, useCongestion);
      if (routeCost >= 0x3fffffff) return null;

      // Cache result
      _cache[cacheKey] = _CacheEntry(routeCost, path);
    }

    final capacityPenalty = facility.penalty;
    final totalScore = routeCost + capacityPenalty;

    return _ScoredFacility(
      nodeId: facility.nodeId,
      totalScore: totalScore,
      routeCost: routeCost,
      capacityPenalty: capacityPenalty,
      path: path,
    );
  }

  /// Calculate total path cost.
  static int _calculatePathCost(List<StadiumNode> path, bool useCongestion) {
    if (path.isEmpty) return 0x3fffffff;
    if (path.length < 2) return 0;
    int total = 0;

    for (int i = 0; i < path.length - 1; i++) {
      final baseWeight = StadiumLayout.graph.edges[path[i]]?[path[i + 1]];
      if (baseWeight == null) return 0x3fffffff;

      if (useCongestion) {
        total += CongestionModel.getEffectiveWeight(
          path[i].id,
          path[i + 1].id,
          baseWeight,
        );
      } else {
        total += baseWeight;
      }
    }

    return total;
  }

  /// Get cache key for a route.
  static String _getCacheKey(String startId, String endId) {
    final scenario = CongestionModel.currentScenario.name;
    return '$startId:$endId:$scenario';
  }

  /// Invalidate cache if congestion scenario changed.
  static void _invalidateCacheIfNeeded() {
    final currentScenario = CongestionModel.currentScenario;
    if (_lastScenario != currentScenario) {
      _cache.clear();
      _lastScenario = currentScenario;
    }
  }

  /// Manually invalidate the cache.
  static void invalidateCache() {
    _cache.clear();
    _lastScenario = null;
  }

  /// Get nearest facilities for a section (delegates to SectionFacilityMapping).
  static List<String> getNearestForSection(
      String sectionId, FacilityType type) {
    // Import and use SectionFacilityMapping
    return FacilityCapacityModel.getByType(type)
        .map((f) => f.nodeId)
        .toList();
  }

  /// Select the best facility from the user's current GPS position.
  /// This finds the nearest node first, then routes to the nearest facility.
  static Future<NearestFacilityResult?> selectNearestFromGPS({
    required FacilityType facilityType,
    bool useCongestion = true,
  }) async {
    // Get current position and find nearest node
    final nearestNode = await LocationService.findNearestNode();
    if (nearestNode == null) {
      return null;
    }

    // Use existing selectBest method to find best facility from that node
    final result = selectBest(
      startNodeId: nearestNode.nodeId,
      facilityType: facilityType,
      useCongestion: useCongestion,
    );

    return NearestFacilityResult(
      startNodeId: nearestNode.nodeId,
      startNodeLabel: nearestNode.nodeLabel,
      distanceFromUser: nearestNode.distanceMeters,
      userLat: nearestNode.userLat,
      userLng: nearestNode.userLng,
      facilityResult: result,
    );
  }

  /// Select the best facility from specific coordinates (without GPS call).
  static NearestFacilityResult? selectNearestFromPosition({
    required double lat,
    required double lng,
    required FacilityType facilityType,
    bool useCongestion = true,
  }) {
    // Find nearest node from position
    final nearestNode = LocationService.findNearestNodeFromPosition(lat, lng);
    if (nearestNode == null) {
      return null;
    }

    // Use existing selectBest method to find best facility from that node
    final result = selectBest(
      startNodeId: nearestNode.nodeId,
      facilityType: facilityType,
      useCongestion: useCongestion,
    );

    return NearestFacilityResult(
      startNodeId: nearestNode.nodeId,
      startNodeLabel: nearestNode.nodeLabel,
      distanceFromUser: nearestNode.distanceMeters,
      userLat: lat,
      userLng: lng,
      facilityResult: result,
    );
  }
}

/// Result of finding nearest facility from GPS position.
class NearestFacilityResult {
  /// The nearest stadium node to the user's position (used as path start).
  final String startNodeId;
  final String startNodeLabel;

  /// Distance from user to the start node (in meters).
  final double distanceFromUser;

  /// User's GPS coordinates.
  final double userLat;
  final double userLng;

  /// The facility selection result (contains path, recommended facility, etc.).
  final FacilitySelectionResult facilityResult;

  NearestFacilityResult({
    required this.startNodeId,
    required this.startNodeLabel,
    required this.distanceFromUser,
    required this.userLat,
    required this.userLng,
    required this.facilityResult,
  });

  /// Get the recommended facility node ID.
  String get recommendedFacilityId => facilityResult.recommendedNodeId;

  /// Get the computed path.
  List<StadiumNode> get path => facilityResult.path;

  /// Get formatted distance from user to start node.
  String get formattedDistanceToStart {
    if (distanceFromUser < 1000) {
      return '${distanceFromUser.toStringAsFixed(0)}m';
    } else {
      return '${(distanceFromUser / 1000).toStringAsFixed(1)}km';
    }
  }
}

/// Internal scored facility for sorting.
class _ScoredFacility {
  final String nodeId;
  final int totalScore;
  final int routeCost;
  final int capacityPenalty;
  final List<StadiumNode> path;

  _ScoredFacility({
    required this.nodeId,
    required this.totalScore,
    required this.routeCost,
    required this.capacityPenalty,
    required this.path,
  });
}
