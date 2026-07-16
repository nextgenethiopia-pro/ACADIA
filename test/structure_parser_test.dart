import 'package:flutter_test/flutter_test.dart';

import 'package:acadia/src/core/content/structure_parser.dart';

void main() {
  group('StructureParser', () {
    test('parses a tree listing into nested nodes', () {
      const text = '''
Folder PATH listing
Volume serial number is 1E8D-DE7A
C:.
+---high-school
|   +---Grade_10
|   |   +---biology
|   |   |   +---Unit 1_ SUB-FIELDS OF BIOLOGY
|   |   |   |   +---exam
|   |   |   |   \\---video
|   |   |   \\---Unit 2_ PLANTS
|   |   |       \\---quiz
|   |   \\---chemistry
|   |       \\---Unit 1_ SOLUTIONS
\\---university
    \\---freshman
        \\---first_semister
            \\---natural_science
                \\---english
                    \\---Chapter 1_ study skills
''';

      final root = StructureParser.parse(text);
      expect(root.childNames, ['high-school', 'university']);

      final hs = root.child('high-school')!;
      expect(hs.childNames, ['Grade_10']);

      final g10 = hs.child('Grade_10')!;
      expect(g10.childNames, ['biology', 'chemistry']);

      final biology = g10.child('biology')!;
      expect(biology.children.length, 2);
      expect(biology.child('Unit 1_ SUB-FIELDS OF BIOLOGY')!.childNames,
          ['exam', 'video']);
      expect(biology.child('Unit 2_ PLANTS')!.childNames, ['quiz']);

      final uni = root.child('university')!;
      final english = uni
          .child('freshman')!
          .child('first_semister')!
          .child('natural_science')!
          .child('english')!;
      expect(english.childNames, ['Chapter 1_ study skills']);
    });

    test('ignores blank lines and header noise', () {
      const text = '''
Folder PATH listing

+---high-school
''';
      final root = StructureParser.parse(text);
      expect(root.childNames, ['high-school']);
    });
  });
}
