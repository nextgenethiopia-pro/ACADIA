import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'structure_node.dart';
import 'structure_parser.dart';

/// StructureService
///
/// Loads the canonical academic path (`structure.txt`) that defines grades,
/// streams, subjects, units/chapters and content types, and exposes it as a
/// queryable tree. This lets the academic path change from the GitHub content
/// repo without rebuilding the APK.
///
/// Load order:
/// 1. GitHub content repo raw `structure.txt` (network).
/// 2. Locally cached copy from a previous successful fetch.
/// 3. Bundled asset `assets/structure.txt` (guaranteed fallback).
class StructureService {
  StructureService._internal();
  static final StructureService instance = StructureService._internal();

  static const String _cacheKey = 'structure_txt_cache';
  static const String _assetPath = 'assets/structure.txt';

  StructureNode? _root;
  bool _initialized = false;

  bool get isLoaded => _root != null;

  /// The six default content types when a unit has none listed.
  static const List<String> defaultContentTypes = [
    'exam',
    'flashcard',
    'past_paper',
    'quiz',
    'short_note',
    'video',
  ];

  /// Loads and parses the structure. Safe to call multiple times; pass
  /// [forceRefresh] to re-fetch from the network.
  Future<void> init({bool forceRefresh = false}) async {
    if (_initialized && !forceRefresh && _root != null) return;

    final text = await _loadText(forceRefresh: forceRefresh);
    if (text != null && text.trim().isNotEmpty) {
      try {
        _root = StructureParser.parse(text);
      } catch (e) {
        debugPrint('StructureService: parse failed: $e');
      }
    }
    _initialized = true;
  }

  Future<String?> _loadText({required bool forceRefresh}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Network (GitHub content repo).
    try {
      final url = '${AppConfig.contentRawBaseUrl}/structure.txt';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        await prefs.setString(_cacheKey, response.body);
        return response.body;
      }
    } catch (e) {
      debugPrint('StructureService: network load failed: $e');
    }

    // 2. Cached copy.
    final cached = prefs.getString(_cacheKey);
    if (cached != null && cached.trim().isNotEmpty) return cached;

    // 3. Bundled asset.
    try {
      return await rootBundle.loadString(_assetPath);
    } catch (e) {
      debugPrint('StructureService: asset load failed: $e');
      return null;
    }
  }

  // ---- High school queries ----

  StructureNode? _highSchool() => _root?.childIgnoreCase('high-school');

  StructureNode? _gradeNode(String grade) {
    final hs = _highSchool();
    if (hs == null) return null;
    return hs.childIgnoreCase('Grade_$grade');
  }

  StructureNode? _highSchoolSubjectContainer(String grade, String? stream) {
    final gradeNode = _gradeNode(grade);
    if (gradeNode == null) return null;
    // Grades 9 and 10 have subjects directly; 11 and 12 have a stream folder.
    if (grade == '11' || grade == '12') {
      final streamFolder = (stream == 'social')
          ? 'Grade_${grade}_Social_Science'
          : 'Grade_${grade}_Natural_Science';
      return gradeNode.childIgnoreCase(streamFolder);
    }
    return gradeNode;
  }

  /// Subjects for a high-school grade/stream, normalized to display names.
  List<String> highSchoolSubjects(String grade, String? stream) {
    final container = _highSchoolSubjectContainer(grade, stream);
    if (container == null) return const [];
    return container.children
        .map((n) => _normalizeSubject(n.name))
        .toList(growable: false);
  }

  /// Units for a high-school subject, normalized to "Unit N: TITLE".
  List<String> highSchoolUnits(String grade, String? stream, String subject) {
    final container = _highSchoolSubjectContainer(grade, stream);
    if (container == null) return const [];
    final subjectNode = _matchSubjectNode(container, subject);
    if (subjectNode == null) return const [];
    return subjectNode.children
        .map((n) => _normalizeUnit(n.name))
        .toList(growable: false);
  }

  // ---- University queries ----

  StructureNode? _universitySubjectContainer(
      String semester, String? stream, String? track) {
    final uni = _root?.childIgnoreCase('university');
    final freshman = uni?.childIgnoreCase('freshman');
    if (freshman == null) return null;

    final semFolder =
        semester == '2' ? 'second_semister' : 'first_semister';
    final semNode = freshman.childIgnoreCase(semFolder);
    if (semNode == null) return null;

    if (semester == '2') {
      // Second semester is split by track rather than natural/social.
      final folder = (track == 'pre-engineering_courses')
          ? 'Pre_Engineering_Courses'
          : 'Other_Natural_Science';
      return semNode.childIgnoreCase(folder);
    }

    final streamFolder =
        stream == 'social' ? 'social_science' : 'natural_science';
    return semNode.childIgnoreCase(streamFolder);
  }

  List<String> universitySubjects(
      String semester, String? stream, String? track) {
    final container = _universitySubjectContainer(semester, stream, track);
    if (container == null) return const [];
    return container.children
        .map((n) => _normalizeSubject(n.name))
        .toList(growable: false);
  }

  List<String> universityUnits(
      String semester, String? stream, String subject, String? track) {
    final container = _universitySubjectContainer(semester, stream, track);
    if (container == null) return const [];
    final subjectNode = _matchSubjectNode(container, subject);
    if (subjectNode == null) return const [];
    return subjectNode.children
        .map((n) => _normalizeUnit(n.name))
        .toList(growable: false);
  }

  // ---- Helpers ----

  StructureNode? _matchSubjectNode(StructureNode container, String subject) {
    // Match against both the raw folder name and the normalized display name.
    for (final n in container.children) {
      if (n.name.toLowerCase() == subject.toLowerCase() ||
          _normalizeSubject(n.name).toLowerCase() == subject.toLowerCase()) {
        return n;
      }
    }
    return null;
  }

  static const Map<String, String> _subjectOverrides = {
    'it': 'IT',
    'ict': 'ICT',
  };

  String _normalizeSubject(String raw) {
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();
    if (_subjectOverrides.containsKey(lower)) return _subjectOverrides[lower]!;
    // Preserve names that already contain capitals/spaces (e.g. "Applied
    // Mathematics", "C++ Programming").
    if (trimmed != lower) return trimmed;
    return trimmed
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Converts "Unit 1_ TITLE" / "Chapter 1_ title" to "Unit 1: TITLE".
  String _normalizeUnit(String raw) {
    return raw.replaceFirst('_ ', ': ').replaceFirst('_', ':').trim();
  }
}
