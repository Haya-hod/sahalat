import 'package:flutter_test/flutter_test.dart';
import 'package:sahalat/domain/congestion_model.dart';
import 'package:sahalat/domain/pathfinder.dart';
import 'package:sahalat/domain/stadium_layout.dart';

/// Regression: client paths must follow rings, not cut through concourseMain hub.
void main() {
  setUp(() {
    StadiumLayout.buildOnce();
  });

  List<String> idsFor(String start, String goal, CongestionScenario scenario) {
    CongestionModel.setScenario(scenario);
    final path = Pathfinder.findPath(
      graph: StadiumLayout.graph,
      start: StadiumLayout.nodesById[start]!,
      end: StadiumLayout.nodesById[goal]!,
      useCongestion: true,
    );
    return path.map((n) => n.id).toList();
  }

  test('Gate B → VIP avoids concourseMain (AllLow)', () {
    final ids = idsFor('gateB', 'vip', CongestionScenario.allLow);
    expect(ids, isNot(contains('concourseMain')));
    expect(ids.first, 'gateB');
    expect(ids.last, 'vip');
    expect(ids, contains('ringS'));
    expect(ids, contains('ringN'));
  });

  test('Gate A → VIP avoids concourseMain (AllLow)', () {
    final ids = idsFor('gateA', 'vip', CongestionScenario.allLow);
    expect(ids, isNot(contains('concourseMain')));
    expect(ids.first, 'gateA');
    expect(ids.last, 'vip');
  });

  test('Gate B → VIP avoids concourseMain (RingHigh — no hub shortcut)', () {
    final ids = idsFor('gateB', 'vip', CongestionScenario.ringHigh);
    expect(ids, isNot(contains('concourseMain')));
    expect(ids.last, 'vip');
  });
}
