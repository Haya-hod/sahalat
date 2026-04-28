import 'stadium_graph.dart';
import 'stadium_models.dart';
import 'dijkstra_pathfinder.dart';
import 'astar_pathfinder.dart';

/// Available pathfinding algorithms.
enum PathfindingAlgorithm {
  /// Dijkstra's algorithm - finds shortest path without heuristic.
  /// Guaranteed to find optimal path. Explores more nodes than A*.
  dijkstra,

  /// A* algorithm - uses heuristic for informed search.
  /// More efficient than Dijkstra when heuristic is accurate.
  aStar,
}

/// Extension for user-friendly algorithm names.
extension PathfindingAlgorithmExtension on PathfindingAlgorithm {
  String get displayName {
    switch (this) {
      case PathfindingAlgorithm.dijkstra:
        return 'Dijkstra';
      case PathfindingAlgorithm.aStar:
        return 'A* (A-Star)';
    }
  }

  String get arabicName {
    switch (this) {
      case PathfindingAlgorithm.dijkstra:
        return 'خوارزمية دايكسترا';
      case PathfindingAlgorithm.aStar:
        return 'خوارزمية A*';
    }
  }
}

/// Unified pathfinding interface.
///
/// Provides a single entry point for pathfinding that can use
/// either Dijkstra or A* algorithm based on configuration.
///
/// Example usage:
/// ```dart
/// final path = Pathfinder.findPath(
///   graph: StadiumLayout.graph,
///   start: startNode,
///   end: endNode,
///   algorithm: PathfindingAlgorithm.aStar,
///   useCongestion: true,
/// );
/// ```
class Pathfinder {
  Pathfinder._();

  /// Finds the shortest path between [start] and [end] nodes.
  ///
  /// Parameters:
  /// - [graph]: The stadium graph containing nodes and edges
  /// - [start]: Starting node
  /// - [end]: Destination node
  /// - [algorithm]: Algorithm to use (defaults to A*)
  /// - [useCongestion]: Whether to apply congestion penalties (defaults to true)
  ///
  /// Returns an ordered list of [StadiumNode] representing the path.
  static List<StadiumNode> findPath({
    required StadiumGraph graph,
    required StadiumNode start,
    required StadiumNode end,
    PathfindingAlgorithm algorithm = PathfindingAlgorithm.aStar,
    bool useCongestion = true,
  }) {
    switch (algorithm) {
      case PathfindingAlgorithm.dijkstra:
        return DijkstraPathfinder.findPath(
          graph: graph,
          start: start,
          end: end,
          useCongestion: useCongestion,
        );
      case PathfindingAlgorithm.aStar:
        return AStarPathfinder.findPath(
          graph: graph,
          start: start,
          end: end,
          useCongestion: useCongestion,
        );
    }
  }
}
