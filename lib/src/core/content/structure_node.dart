/// A node in the academic structure tree parsed from `structure.txt`.
///
/// The tree mirrors the folder listing:
/// root → high-school / university → grade/stream/semester → subject →
/// unit/chapter → content type.
class StructureNode {
  StructureNode(this.name, {StructureNode? parent})
      : parent = parent,
        children = <StructureNode>[];

  final String name;
  final StructureNode? parent;
  final List<StructureNode> children;

  bool get isLeaf => children.isEmpty;

  List<String> get childNames =>
      children.map((c) => c.name).toList(growable: false);

  StructureNode? child(String name) {
    for (final c in children) {
      if (c.name == name) return c;
    }
    return null;
  }

  /// Case-insensitive child lookup.
  StructureNode? childIgnoreCase(String name) {
    final lower = name.toLowerCase();
    for (final c in children) {
      if (c.name.toLowerCase() == lower) return c;
    }
    return null;
  }

  @override
  String toString() => 'StructureNode($name, children: ${children.length})';
}
