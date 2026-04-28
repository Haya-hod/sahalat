import 'package:flutter/material.dart';
import '../domain/stadium_layout.dart';
import '../domain/dijkstra_pathfinder.dart';
import '../domain/stadium_models.dart';

class PathTestScreen extends StatelessWidget {
  const PathTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final graph = StadiumLayout.build();

    final start = StadiumNode(id: 'Gate A', type: NodeType.gate);
    final end = StadiumNode(id: 'VIP Section', type: NodeType.section);

    final path = DijkstraPathfinder.findPath(
      graph: graph,
      start: start,
      end: end,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Path Test')),
      body: ListView(
        children: path
            .map(
              (node) => ListTile(
                leading: Icon(_iconFor(node.type)),
                title: Text(node.id),
                subtitle: Text(node.type.name),
              ),
            )
            .toList(),
      ),
    );
  }

  static IconData _iconFor(NodeType type) {
    switch (type) {
      case NodeType.gate:
        return Icons.door_front_door;
      case NodeType.concourse:
        return Icons.alt_route;
      case NodeType.section:
        return Icons.event_seat;
      case NodeType.poi:
        return Icons.place;
    }
  }
}
