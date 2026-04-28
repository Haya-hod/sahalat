import 'package:flutter_test/flutter_test.dart';
import 'package:sahalat/domain/congestion_model.dart';
import 'package:sahalat/domain/pathfinder.dart';
import 'package:sahalat/domain/stadium_layout.dart';

void main() {
  test('Gate A to Food Court 1 avoids detour via ringN (A* + Dijkstra)', () {
    StadiumLayout.buildOnce();
    CongestionModel.reset();
    CongestionModel.setScenario(CongestionScenario.allLow);

    final start = StadiumLayout.nodesById['gateA']!;
    final goal = StadiumLayout.nodesById['food1']!;

    for (final algo in PathfindingAlgorithm.values) {
      final path = Pathfinder.findPath(
        graph: StadiumLayout.graph,
        start: start,
        end: goal,
        algorithm: algo,
        useCongestion: true,
      );

      expect(path.map((n) => n.id).toList(), ['gateA', 'ringW', 'food1'],
          reason: 'optimal path should use direct ringW–food1 spur, not ringN');
    }
  });
}
