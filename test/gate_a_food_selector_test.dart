import 'package:flutter_test/flutter_test.dart';
import 'package:sahalat/domain/congestion_model.dart';
import 'package:sahalat/domain/facility_capacity_model.dart';
import 'package:sahalat/domain/facility_selector.dart';
import 'package:sahalat/domain/stadium_layout.dart';

void main() {
  test('Food from Gate A recommends Food Court 1 (food1), not legacy foodCourt', () {
    FacilityCapacityModel.reset();
    FacilitySelector.invalidateCache();
    StadiumLayout.buildOnce();
    FacilityCapacityModel.initialize();
    CongestionModel.reset();
    CongestionModel.setScenario(CongestionScenario.allLow);

    final result = FacilitySelector.selectBest(
      startNodeId: 'gateA',
      facilityType: FacilityType.food,
    );

    expect(result.recommendedNodeId, 'food1');
    expect(result.path.map((n) => n.id).toList(), ['gateA', 'ringW', 'food1']);
  });
}
