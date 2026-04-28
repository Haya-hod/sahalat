import 'stadium_graph.dart';
import 'stadium_models.dart';

class StadiumLayout {
  StadiumLayout._();

  static bool _built = false;

  // Graph ready for UI use
  static final StadiumGraph graph = StadiumGraph();

  // Nodes lookup by id (important for UI)
  static final Map<String, StadiumNode> nodesById = {};

  /// Build once only
  static void buildOnce() {
    if (_built) return;
    _built = true;

    /// ===== Gates =====
    final gateA = StadiumNode(id: 'gateA', type: NodeType.gate);
    final gateB = StadiumNode(id: 'gateB', type: NodeType.gate);
    final gateC = StadiumNode(id: 'gateC', type: NodeType.gate);
    final gateD = StadiumNode(id: 'gateD', type: NodeType.gate);

    /// ===== Concourse =====
    final concourseMain =
        StadiumNode(id: 'concourseMain', type: NodeType.concourse);

    /// ===== Ring Walkway (Outer Concourse) =====
    final ringN = StadiumNode(id: 'ringN', type: NodeType.concourse);
    final ringE = StadiumNode(id: 'ringE', type: NodeType.concourse);
    final ringS = StadiumNode(id: 'ringS', type: NodeType.concourse);
    final ringW = StadiumNode(id: 'ringW', type: NodeType.concourse);

    /// ===== Sections =====
    final vip = StadiumNode(id: 'vip', type: NodeType.section);
    final standard = StadiumNode(id: 'standard', type: NodeType.section);

    /// ===== POI (Legacy) =====
    final restroom = StadiumNode(id: 'restroom', type: NodeType.poi);
    final foodCourt = StadiumNode(id: 'foodCourt', type: NodeType.poi);

    /// ===== POI (Phase 5 - Multiple Facilities) =====
    final food1 = StadiumNode(id: 'food1', type: NodeType.poi);
    final food2 = StadiumNode(id: 'food2', type: NodeType.poi);
    final food3 = StadiumNode(id: 'food3', type: NodeType.poi);
    final wc1 = StadiumNode(id: 'wc1', type: NodeType.poi);
    final wc2 = StadiumNode(id: 'wc2', type: NodeType.poi);
    final wc3 = StadiumNode(id: 'wc3', type: NodeType.poi);

    // Register nodes
    for (final n in [
      gateA,
      gateB,
      gateC,
      gateD,
      concourseMain,
      ringN,
      ringE,
      ringS,
      ringW,
      vip,
      standard,
      restroom,
      foodCourt,
      // Phase 5 facilities
      food1,
      food2,
      food3,
      wc1,
      wc2,
      wc3,
    ]) {
      nodesById[n.id] = n;
    }

    /// ===== Graph edges (aligned with Unity AR graph) =====
    /// High cost on gate/POI ↔ main concourse so routes prefer the ring
    /// walkway and avoid cutting through the center / pitch zone.

    // Gates ↔ main concourse — very expensive vs ring (match Unity StadiumLayout)
    graph.addEdge(gateA, concourseMain, 55);
    graph.addEdge(gateB, concourseMain, 55);
    graph.addEdge(gateC, concourseMain, 55);
    graph.addEdge(gateD, concourseMain, 55);

    // Gates ↔ ring (preferred entry/exit)
    graph.addEdge(gateA, ringW, 3);
    graph.addEdge(gateB, ringS, 3);
    graph.addEdge(gateC, ringE, 3);
    graph.addEdge(gateD, ringN, 3);

    // Ring loop
    graph.addEdge(ringN, ringE, 4);
    graph.addEdge(ringE, ringS, 4);
    graph.addEdge(ringS, ringW, 4);
    graph.addEdge(ringW, ringN, 4);

    // Ring ↔ concourse — costly shortcut through hub
    graph.addEdge(ringN, concourseMain, 45);
    graph.addEdge(ringE, concourseMain, 45);
    graph.addEdge(ringS, concourseMain, 45);
    graph.addEdge(ringW, concourseMain, 45);

    // Sections
    graph.addEdge(concourseMain, vip, 3);
    graph.addEdge(concourseMain, standard, 48);
    graph.addEdge(ringN, vip, 4);
    graph.addEdge(ringS, standard, 4);

    // Legacy POIs — ring-first; concourse link available but penalized
    graph.addEdge(concourseMain, restroom, 18);
    graph.addEdge(ringW, restroom, 3);
    graph.addEdge(concourseMain, foodCourt, 18);
    graph.addEdge(ringE, foodCourt, 3);

    /// Phase 5 facilities
    graph.addEdge(food1, ringN, 2);
    graph.addEdge(food1, ringW, 2); // NW food court — reachable from west ring without detouring via N
    graph.addEdge(food1, concourseMain, 18);
    graph.addEdge(food2, ringE, 2);
    graph.addEdge(food2, concourseMain, 18);
    graph.addEdge(food3, ringS, 2);
    graph.addEdge(food3, concourseMain, 18);

    graph.addEdge(wc1, ringW, 2);
    graph.addEdge(wc1, concourseMain, 18);
    graph.addEdge(wc2, ringN, 2);
    graph.addEdge(wc2, ringE, 3);
    graph.addEdge(wc2, concourseMain, 18);
    graph.addEdge(wc3, ringS, 2);
    graph.addEdge(wc3, ringW, 3);
    graph.addEdge(wc3, concourseMain, 18);
  }

  /// Optional: returns graph after building
  static StadiumGraph build() {
    buildOnce();
    return graph;
  }

  /// Labels for UI
  static String labelOf(String id) {
    switch (id) {
      case 'gateA':
        return 'Gate A';
      case 'gateB':
        return 'Gate B';
      case 'gateC':
        return 'Gate C';
      case 'gateD':
        return 'Gate D';
      case 'concourseMain':
        return 'Main Concourse';
      case 'ringN':
        return 'North Ring';
      case 'ringE':
        return 'East Ring';
      case 'ringS':
        return 'South Ring';
      case 'ringW':
        return 'West Ring';
      case 'vip':
        return 'VIP Section';
      case 'standard':
        return 'Standard Section';
      case 'restroom':
        return 'Restrooms';
      case 'foodCourt':
        return 'Food Court';
      // Phase 5 facilities
      case 'food1':
        return 'Food Court 1';
      case 'food2':
        return 'Food Court 2';
      case 'food3':
        return 'Food Court 3';
      case 'wc1':
        return 'Restroom 1';
      case 'wc2':
        return 'Restroom 2';
      case 'wc3':
        return 'Restroom 3';
      default:
        return id;
    }
  }
}
