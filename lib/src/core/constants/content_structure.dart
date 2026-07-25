import 'academic_structure.dart';

/// Maps a subject's units/chapters to the content types that are expected
/// to be available for each of them.
///
/// This is a lightweight, fully offline helper used by the Subject Portal
/// screen to build its initial UI (unit list + content type chips) before
/// real content metadata is fetched from GitHub/Firestore. It intentionally
/// mirrors [AcademicStructure]'s chapter data so unit names stay consistent
/// across the app.
class ContentStructure {
  ContentStructure._();

  /// Standard content types offered per unit/chapter across the app.
  ///
  /// Order matches the Chapter Content screen's display order:
  /// Video -> Short Note -> Quiz -> Exam -> Flashcard -> Past Paper.
  static const List<String> defaultContentTypes = [
    'video',
    'short_note',
    'quiz',
    'exam',
    'flashcard',
    'past_paper',
  ];

  /// Returns a map of unit/chapter name -> list of content types for the
  /// given [grade], [stream], and [subject].
  ///
  /// - For high school grades ('9', '10', '11', '12'), chapters are resolved
  ///   via [AcademicStructure.getChapters].
  /// - For university subjects, pass the semester ('1' or '2') as [grade];
  ///   chapters are resolved via [AcademicStructure.getUniversityChapters].
  ///   [track] is only relevant for semester 2 (e.g. 'pre-engineering_courses').
  ///
  /// Every resolved unit is given the same [defaultContentTypes] list, since
  /// the actual per-unit availability is determined later from live content
  /// metadata (GitHub/Firestore), not from this static academic structure.
  static Map<String, List<String>> getSubjectContent(
    String grade,
    String stream,
    String subject, [
    String? track,
  ]) {
    final chapters = _getChapters(grade, stream, subject, track);

    final Map<String, List<String>> structure = {};
    for (final chapter in chapters) {
      structure[chapter] = List<String>.from(defaultContentTypes);
    }
    return structure;
  }

  /// Resolves the chapter/unit list for [subject] given [grade] and [stream].
  ///
  /// Falls back to the university chapter lookup when [grade] isn't one of
  /// the recognized high school grades (i.e. it's being used as a semester
  /// identifier such as '1' or '2').
  static List<String> _getChapters(
    String grade,
    String stream,
    String subject,
    String? track,
  ) {
    if (AcademicStructure.grades.contains(grade)) {
      return AcademicStructure.getChapters(grade, stream, subject);
    }

    return AcademicStructure.getUniversityChapters(
      grade,
      stream,
      subject,
      track,
    );
  }

  /// Returns true if [contentType] is one of the recognized content types
  /// (video, short_note, quiz, exam, flashcard, past_paper).
  static bool isValidContentType(String contentType) {
    return defaultContentTypes.contains(contentType);
  }

  /// Human-friendly display name for a content type key.
  static String displayNameFor(String contentType) {
    return AcademicStructure.contentTypeDisplayNames[contentType] ??
        contentType;
  }
}
