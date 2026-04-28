enum NodeType {
  gate,
  concourse,
  section,
  poi,
}

class StadiumNode {
  final String id;
  final NodeType type;

  StadiumNode({
    required this.id,
    required this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StadiumNode && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
