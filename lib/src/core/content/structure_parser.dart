import 'structure_node.dart';

/// Parses the Windows `tree`-style `structure.txt` into a [StructureNode] tree.
///
/// Each level is indented by a 4-character group (`|   ` or four spaces) and the
/// node itself is introduced by `+---` or `\---`. Header lines produced by the
/// `tree` command (e.g. "Folder PATH listing", "Volume ...", "C:.") are ignored.
class StructureParser {
  const StructureParser._();

  static final RegExp _nodePattern = RegExp(r'^(.*?)[+\\]---(.*)$');

  /// Parses [text] and returns the synthetic root node whose children are the
  /// top-level entries (e.g. `high-school`, `university`).
  static StructureNode parse(String text) {
    final root = StructureNode('__root__');
    // Stack of (depth, node); depth 0 == top-level entry, parented to root.
    final stack = <_Entry>[];

    for (final rawLine in text.split('\n')) {
      final line = rawLine.replaceAll('\r', '');
      if (line.trim().isEmpty) continue;

      final match = _nodePattern.firstMatch(line);
      if (match == null) continue; // header / non-tree line

      final prefix = match.group(1)!;
      final name = match.group(2)!.trim();
      if (name.isEmpty) continue;

      final depth = _depthFromPrefix(prefix);

      // Pop back to the parent depth.
      while (stack.isNotEmpty && stack.last.depth >= depth) {
        stack.removeLast();
      }

      final parent = stack.isEmpty ? root : stack.last.node;
      final node = StructureNode(name, parent: parent);
      parent.children.add(node);
      stack.add(_Entry(depth, node));
    }

    return root;
  }

  static int _depthFromPrefix(String prefix) {
    // Every level contributes exactly 4 leading characters ("|   " or "    ").
    return prefix.length ~/ 4;
  }
}

class _Entry {
  _Entry(this.depth, this.node);
  final int depth;
  final StructureNode node;
}
