import 'academic_structure.dart';

/// ContentStructure
///
/// Thin helper that maps an academic subject to its per-unit content layout.
/// Each unit exposes the same set of content types (video, short note, quiz,
/// exam, flashcard, past paper) defined in [AcademicStructure.contentTypes].
class ContentStructure {
  /// Returns a map of unit name -> available content types for a subject.
  static Map<String, List<String>> getSubjectContent(
    String grade,
    String stream,
    String subject,
  ) {
    final units = AcademicStructure.getChapters(grade, stream, subject);
    return {
      for (final unit in units) unit: List<String>.from(AcademicStructure.contentTypes),
    };
  }
}
