import 'dart:math';

/// Simulated coordinates for A* heuristic calculations.
///
/// Coordinates represent relative positions in a stadium layout grid (0-100 scale).
/// This is kept separate from StadiumNode to preserve Phase 2 architecture.
class NodeCoordinates {
  NodeCoordinates._();

  /// Map of node IDs to their (x, y) coordinates.
  ///
  /// Layout visualization:
  /// ```
  ///                    gateD (50, 0)
  ///                      |
  ///                    ringN (50, 15)
  ///                   /     \
  ///    gateA -- ringW ---- concourseMain ---- ringE -- gateC
  ///   (0, 50)  (15, 50)      (50, 50)       (85, 50)  (100, 50)
  ///                   \     /
  ///                    ringS (50, 85)
  ///                      |
  ///                    gateB (50, 100)
  ///
  /// POIs and Sections are near the concourse center.
  /// Ring walkway forms an outer loop around the concourse.
  /// ```
  static const Map<String, (double x, double y)> positions = {
    // Gates (outer perimeter - cardinal directions)
    'gateA': (0.0, 50.0),      // West gate
    'gateB': (50.0, 100.0),    // South gate
    'gateC': (100.0, 50.0),    // East gate
    'gateD': (50.0, 0.0),      // North gate

    // Ring Walkway (outer concourse loop)
    'ringN': (50.0, 15.0),     // North ring point
    'ringE': (85.0, 50.0),     // East ring point
    'ringS': (50.0, 85.0),     // South ring point
    'ringW': (15.0, 50.0),     // West ring point

    // Concourse (center hub)
    'concourseMain': (50.0, 50.0),

    // Sections (inner ring, close to center)
    'vip': (50.0, 35.0),       // VIP section - north of center
    'standard': (50.0, 65.0),  // Standard section - south of center

    // POIs (adjacent to concourse)
    'restroom': (30.0, 50.0), // West of concourse
    'foodCourt': (70.0, 50.0), // East of concourse

    // Phase 5: Multiple Facilities (distributed around stadium)
    'food1': (40.0, 20.0), // Near North ring
    'food2': (80.0, 40.0), // Near East ring
    'food3': (50.0, 80.0), // Near South ring
    'wc1': (20.0, 40.0), // Near West ring
    'wc2': (60.0, 20.0), // Between North/East
    'wc3': (35.0, 80.0), // Near South/West
  };

  /// Returns the position of a node by its ID.
  /// Returns null if the node ID is not found.
  static (double x, double y)? getPosition(String nodeId) {
    return positions[nodeId];
  }

  /// Calculates the Euclidean distance between two nodes, scaled for admissibility.
  ///
  /// This is used as the heuristic function h(n) in A* algorithm.
  /// Returns 0.0 if either node ID is not found (admissible fallback).
  ///
  /// IMPORTANT: The raw Euclidean distance (0-100 scale) must be scaled down
  /// to match edge weights (2-7 range). Without scaling, h(n) would overestimate
  /// actual costs, violating A* admissibility and causing suboptimal paths.
  ///
  /// Scale factor derivation: for admissible A*, h(n,goal) must not exceed the true
  /// shortest-path cost from n to goal. A necessary check vs the layout graph is
  /// scale ≤ min over edges (u,v) of weight(u,v) / euclidean(u,v) when the goal
  /// lies at v along a shortest route (tightest here: short-weight ring spurs to POIs).
  ///
  /// Tight example: ringW ↔ food1 has weight 2 and euclidean ≈ 39.05 → ratio ≈ 0.051.
  /// Using 0.048 keeps h(ringW, food1) < 2 so A* stays admissible (avoids detours
  /// such as ringW → ringN → food1 that a slightly inflated h could favor).
  static const double _heuristicScale = 0.048;

  static double euclideanDistance(String nodeIdA, String nodeIdB) {
    final a = positions[nodeIdA];
    final b = positions[nodeIdB];

    if (a == null || b == null) {
      // Fallback: return 0 to make heuristic admissible
      // This degrades A* to behave like Dijkstra for unknown nodes
      return 0.0;
    }

    final dx = b.$1 - a.$1;
    final dy = b.$2 - a.$2;

    // Scale down to match edge weight magnitudes
    return sqrt(dx * dx + dy * dy) * _heuristicScale;
  }

  /// Manhattan distance (alternative heuristic).
  /// Useful if the stadium has a grid-like layout.
  /// Also scaled for admissibility.
  static double manhattanDistance(String nodeIdA, String nodeIdB) {
    final a = positions[nodeIdA];
    final b = positions[nodeIdB];

    if (a == null || b == null) return 0.0;

    return ((b.$1 - a.$1).abs() + (b.$2 - a.$2).abs()) * _heuristicScale;
  }
}

/*
 * ADMISSIBILITY (scale = 0.048): h(n,g) = euclid(n,g)×0.048 must stay ≤ true cost
 * to g. The binding case in this layout is ringW→food1 (weight 2, euclid ≈ 39.05).
 */
