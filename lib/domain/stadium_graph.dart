import 'stadium_models.dart';

class StadiumGraph {
  final Map<StadiumNode, Map<StadiumNode, int>> _edges = {};

  void addEdge(StadiumNode from, StadiumNode to, int weight) {
    _edges.putIfAbsent(from, () => {});
    _edges.putIfAbsent(to, () => {});
    _edges[from]![to] = weight;
    _edges[to]![from] = weight;
  }

  Map<StadiumNode, Map<StadiumNode, int>> get edges => _edges;
}
