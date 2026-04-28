import 'stadium_graph.dart';
import 'stadium_models.dart';
import 'congestion_model.dart';

class DijkstraPathfinder {
  /// Finds the shortest path using Dijkstra's algorithm.
  ///
  /// When [useCongestion] is true, edge weights are adjusted by
  /// congestion penalties from [CongestionModel].
  static List<StadiumNode> findPath({
    required StadiumGraph graph,
    required StadiumNode start,
    required StadiumNode end,
    bool useCongestion = false,
  }) {
    final distances = <StadiumNode, int>{};
    final previous = <StadiumNode, StadiumNode?>{};
    final unvisited = <StadiumNode>{};

    for (final node in graph.edges.keys) {
      distances[node] = node == start ? 0 : 999999;
      previous[node] = null;
      unvisited.add(node);
    }

    while (unvisited.isNotEmpty) {
      final current = unvisited.reduce(
        (a, b) => distances[a]! < distances[b]! ? a : b,
      );

      if (current == end) break;

      unvisited.remove(current);

      for (final neighbor in graph.edges[current]!.keys) {
        final baseWeight = graph.edges[current]![neighbor]!;

        // Apply congestion penalty if enabled
        final effectiveWeight = useCongestion
            ? CongestionModel.getEffectiveWeight(
                current.id, neighbor.id, baseWeight)
            : baseWeight;

        final alt = distances[current]! + effectiveWeight;
        if (alt < distances[neighbor]!) {
          distances[neighbor] = alt;
          previous[neighbor] = current;
        }
      }
    }

    final path = <StadiumNode>[];
    StadiumNode? current = end;

    while (current != null) {
      path.insert(0, current);
      current = previous[current];
    }

    return path;
  }
}
