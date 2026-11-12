import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:dio/dio.dart';
import 'package:acadia/src/core/services/content_file_guard.dart';
import 'package:acadia/src/local_database/isar_service.dart';

/// User-facing failure while preparing a document, kept separate from generic
/// exceptions so the reader can show the real recoverable reason.
class ContentPdfException implements Exception {
  ContentPdfException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Generates professional educational PDFs from structured GitHub JSON
/// and caches existing PDFs locally in the app's managed storage.
class ContentPdfGenerator {
  static final ContentPdfGenerator _instance = ContentPdfGenerator._internal();
  factory ContentPdfGenerator() => _instance;
  ContentPdfGenerator._internal();

  final Dio _dio = Dio();
  final IsarService _isarService = IsarService.instance;

  /// Ensures a local PDF exists for the given content.
  /// If it's already a PDF URL, it downloads and caches directly without converting.
  /// If it's a JSON source, it parses the rich structure and generates a PDF.
  Future<String> getOrGeneratePdf({
    required String contentId,
    required String title,
    String? downloadUrl,
    String? rawJsonContent,
    String? userId,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${docsDir.path}/pdfs');
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final targetPdfPath = '${pdfDir.path}/$contentId.pdf';
    final targetFile = File(targetPdfPath);

    // A file that merely exists may be a Git LFS pointer or a truncated
    // download left by an older build. Validate the PDF signature first.
    if (await targetFile.exists()) {
      final len = await targetFile.length();
      if (len > 0 && await ContentFileGuard.isPdfFile(targetPdfPath)) {
        debugPrint('✅ Existing PDF found: $targetPdfPath ($len bytes)');
        return targetPdfPath;
      }
      debugPrint('🧹 Removing invalid cached PDF: $targetPdfPath ($len bytes)');
      await targetFile.delete();
    }

    final url = (downloadUrl ?? '').trim();
    final isRemote = url.startsWith('http://') || url.startsWith('https://');

    // 1. Direct PDF Download (Do not reconvert existing PDFs)
    final isDirectPdf = url.toLowerCase().endsWith('.pdf') ||
        url.toLowerCase().contains('.pdf?');
    if (isDirectPdf) {
      if (!isRemote) {
        // The caller may already have a local PDF (offline chapter).
        if (await File(url).exists()) {
          if (await ContentFileGuard.isPdfFile(url)) {
            await _recordInIsar(
              contentId: contentId,
              title: title,
              filePath: url,
              userId: userId,
            );
            return url;
          }
          await File(url).delete();
        }
        throw ContentPdfException(
            'The saved copy of this document is not a valid PDF. Reconnect and download the chapter again.');
      }

      debugPrint('📥 Downloading existing PDF directly from: $url');
      try {
        await _dio.download(url, targetPdfPath);
        if (await ContentFileGuard.isGitLfsPointerFile(targetPdfPath)) {
          final mediaUrl = ContentFileGuard.gitLfsMediaUrl(url);
          if (mediaUrl == null || mediaUrl == url) {
            await targetFile.delete();
            throw ContentPdfException(
                'The repository returned a Git LFS placeholder instead of the document.');
          }
          debugPrint('🔁 Retrying Git LFS media URL: $mediaUrl');
          await _dio.download(mediaUrl, targetPdfPath);
        }
        if (!await ContentFileGuard.isPdfFile(targetPdfPath)) {
          if (await targetFile.exists()) {
            await targetFile.delete();
          }
          throw ContentPdfException(
              'The downloaded file is not a valid PDF document.');
        }
      } on DioException catch (e) {
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        final timedOut = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout;
        throw ContentPdfException(timedOut
            ? 'The document download timed out. Check your connection and retry.'
            : 'The document could not be downloaded. Check your connection and retry.');
      }

      await _recordInIsar(
        contentId: contentId,
        title: title,
        filePath: targetPdfPath,
        userId: userId,
      );
      return targetPdfPath;
    }

    // 2. Fetch JSON if raw content not supplied
    Map<String, dynamic> jsonData = {};
    if (rawJsonContent != null && rawJsonContent.trim().isNotEmpty) {
      try {
        final decoded = json.decode(rawJsonContent.replaceFirst('\uFEFF', ''));
        if (decoded is Map<String, dynamic>) {
          jsonData = decoded;
        } else {
          throw const FormatException('JSON root is not an object');
        }
      } catch (e) {
        debugPrint('⚠️ Error parsing raw JSON: $e');
        throw ContentPdfException(
            'The saved notes are not valid JSON. Reconnect and download them again.');
      }
    } else if (url.isNotEmpty) {
      String? jsonString;
      if (!isRemote) {
        final localFile = File(url);
        if (!await localFile.exists()) {
          throw ContentPdfException(
              'The saved notes file is missing. Reconnect and download the chapter again.');
        }
        debugPrint('📂 Reading content JSON from local file: $url');
        jsonString = await localFile.readAsString();
      } else {
        debugPrint('🌐 Fetching content JSON from: $url');
        try {
          final res = await _dio.get<String>(url);
          jsonString = res.data;
        } on DioException {
          throw ContentPdfException(
              'The notes could not be downloaded. Check your connection and retry.');
        }
      }
      if (jsonString != null) {
        try {
          final decoded =
              json.decode(jsonString.replaceFirst('\uFEFF', ''));
          if (decoded is Map<String, dynamic>) {
            jsonData = decoded;
          } else if (decoded is List &&
              decoded.isNotEmpty &&
              decoded.first is Map) {
            jsonData = Map<String, dynamic>.from(decoded.first as Map);
          }
        } catch (e) {
          debugPrint('⚠️ Error decoding fetched JSON: $e');
          throw ContentPdfException(
              'The notes content could not be read. Reconnect and try again.');
        }
      }
    }

    if (jsonData.isEmpty) {
      throw ContentPdfException(
          'No readable content was found for this document. Reconnect and try again.');
    }

    // 3. Generate PDF from JSON
    debugPrint('📄 Generating PDF for: $title ($contentId)');
    final Uint8List pdfBytes;
    try {
      pdfBytes = await generatePdfFromJson(jsonData, defaultTitle: title);
    } catch (e) {
      debugPrint('⚠️ PDF generation failed: $e');
      throw ContentPdfException(
          'The document could not be generated from the available notes.');
    }
    if (pdfBytes.isEmpty || !ContentFileGuard.isPdfBytes(pdfBytes)) {
      throw ContentPdfException(
          'The generated document was invalid. Please retry.');
    }

    await targetFile.writeAsBytes(pdfBytes, flush: true);
    if (!await ContentFileGuard.isPdfFile(targetPdfPath)) {
      await targetFile.delete();
      throw ContentPdfException(
          'The generated document could not be written correctly. Please retry.');
    }
    debugPrint('✅ PDF successfully generated: $targetPdfPath (${pdfBytes.length} bytes)');

    await _recordInIsar(
      contentId: contentId,
      title: title,
      filePath: targetPdfPath,
      userId: userId,
    );

    return targetPdfPath;
  }

  Future<void> _recordInIsar({
    required String contentId,
    required String title,
    required String filePath,
    String? userId,
  }) async {
    if (userId == null || userId.isEmpty) return;
    try {
      final existing = await _isarService.getDownloadedContentById(contentId, userId);
      final file = File(filePath);
      final fileSize = await file.exists() ? await file.length() : 0;

      final record = existing ??
          (DownloadedContent()
            ..contentId = contentId
            ..userId = userId
            ..title = title
            ..downloadedAt = DateTime.now());

      record.title = title;
      record.contentType = 'short_note';
      record.contentPath = filePath;
      record.fileSize = fileSize;
      record.isDownloaded = true;
      record.lastAccessed = DateTime.now();

      await _isarService.saveDownloadedContent(record);
    } catch (e) {
      debugPrint('⚠️ Error updating Isar record: $e');
    }
  }

  /// Parses JSON and compiles it into a high-quality multi-page PDF document
  Future<Uint8List> generatePdfFromJson(
    Map<String, dynamic> json, {
    String defaultTitle = 'ACADIA Study Material',
  }) async {
    json = _normalizeNotesDocument(json);
    final pdf = pw.Document(
      title: json['title']?.toString() ?? defaultTitle,
      author: 'ACADIA Digital Education Platform',
    );

    // Document Design & Theme parsing
    final design = json['design'] as Map<String, dynamic>? ??
        json['document_design'] as Map<String, dynamic>? ??
        json['style'] as Map<String, dynamic>? ??
        {};

    final primaryHex = design['primary_color']?.toString() ?? '#111844';
    final accentHex = design['accent_color']?.toString() ?? '#2563EB';
    final primaryColor = PdfColor.fromHex(primaryHex);
    final accentColor = PdfColor.fromHex(accentHex);
    final secondaryColor = PdfColor.fromHex('#4B5563');
    final cardBgColor = PdfColor.fromHex('#F9FAFB');
    final borderColor = PdfColor.fromHex('#E5E7EB');

    final chapterTitle = json['chapter_title']?.toString() ??
        json['title']?.toString() ??
        defaultTitle;
    final chapterSubtitle = json['chapter_subtitle']?.toString() ??
        json['subtitle']?.toString() ??
        json['grade_subject']?.toString();

    final summary = json['summary'] ?? json['chapter_summary'];
    final sections = json['sections'] as List<dynamic>? ??
        json['subsections'] as List<dynamic>? ??
        [];
    final definitions = json['definitions'] as List<dynamic>? ?? [];
    final keyPoints = json['key_points'] as List<dynamic>? ??
        json['keypoints'] as List<dynamic>? ??
        [];
    final formulas = json['formulas'] as List<dynamic>? ?? [];
    final tables = json['tables'] as List<dynamic>? ?? [];
    final diagrams = json['diagrams'] as List<dynamic>? ?? [];
    final exercises = json['exercises'] as List<dynamic>? ??
        json['practice_questions'] as List<dynamic>? ??
        [];
    final answers = json['answers'] as List<dynamic>? ??
        json['solutions'] as List<dynamic>? ??
        json['exercise_answers'] as List<dynamic>? ??
        [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        header: (context) => _buildHeader(chapterTitle, primaryColor, context),
        footer: (context) => _buildFooter(context),
        build: (context) {
          final widgets = <pw.Widget>[];

          // 1. Title Banner
          widgets.add(_buildTitleBanner(
            title: chapterTitle,
            subtitle: chapterSubtitle,
            primaryColor: primaryColor,
            accentColor: accentColor,
          ));
          widgets.add(pw.SizedBox(height: 16));

          // 2. Summary Callout (if available at chapter level)
          if (summary != null) {
            widgets.add(_buildSummaryCard(summary, accentColor, cardBgColor));
            widgets.add(pw.SizedBox(height: 16));
          }

          // 3. Definitions Block (if provided at chapter level)
          if (definitions.isNotEmpty) {
            widgets.add(_buildSectionHeader('Key Definitions', accentColor));
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(_buildDefinitionsList(definitions, primaryColor, cardBgColor, borderColor));
            widgets.add(pw.SizedBox(height: 16));
          }

          // 4. Key Points (if provided at chapter level)
          if (keyPoints.isNotEmpty) {
            widgets.add(_buildSectionHeader('Key Takeaways & Core Concepts', accentColor));
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(_buildKeyPointsList(keyPoints, primaryColor, cardBgColor));
            widgets.add(pw.SizedBox(height: 16));
          }

          // 5. Formulas (if provided at chapter level)
          if (formulas.isNotEmpty) {
            widgets.add(_buildSectionHeader('Important Formulas & Laws', accentColor));
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(_buildFormulasList(formulas, primaryColor, cardBgColor, borderColor));
            widgets.add(pw.SizedBox(height: 16));
          }

          // 6. Tables (if provided at chapter level)
          if (tables.isNotEmpty) {
            widgets.add(_buildSectionHeader('Reference Tables', accentColor));
            widgets.add(pw.SizedBox(height: 8));
            for (final table in tables) {
              if (table is Map) {
                widgets.add(_buildTable(table.cast<String, dynamic>(), primaryColor, borderColor));
                widgets.add(pw.SizedBox(height: 12));
              }
            }
          }

          // 7. Diagrams / Timelines / Charts
          if (diagrams.isNotEmpty) {
            widgets.add(_buildSectionHeader('Diagrams, Charts & Processes', accentColor));
            widgets.add(pw.SizedBox(height: 8));
            for (final diagram in diagrams) {
              if (diagram is Map) {
                widgets.add(_buildDiagram(diagram.cast<String, dynamic>(), primaryColor, cardBgColor, borderColor));
                widgets.add(pw.SizedBox(height: 12));
              }
            }
          }

          // 8. Sections & Subsections
          for (final sec in sections) {
            if (sec is Map) {
              final sectionMap = sec.cast<String, dynamic>();
              widgets.addAll(_buildSection(
                sectionMap,
                primaryColor: primaryColor,
                accentColor: accentColor,
                secondaryColor: secondaryColor,
                cardBg: cardBgColor,
                borderCol: borderColor,
              ));
              widgets.add(pw.SizedBox(height: 16));
            }
          }

          // 9. Exercises
          if (exercises.isNotEmpty) {
            widgets.add(_buildSectionHeader('Exercises & Review Questions', accentColor));
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(_buildExercises(exercises, primaryColor, cardBgColor, borderColor));
            widgets.add(pw.SizedBox(height: 16));
          }

          // 10. Answers & Solutions
          if (answers.isNotEmpty) {
            widgets.add(_buildSectionHeader('Answers & Explanations', accentColor));
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(_buildAnswers(answers, primaryColor, cardBgColor, borderColor));
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  // --- REPOSITORY SCHEMA NORMALIZATION ---

  /// The repository's short-note files nest content under `chapter` and use
  /// field names such as `section_title`, `subsection_title` and
  /// `chapter_introduction`. Normalize them into the flat schema used by the
  /// PDF builders so real content is never discarded.
  Map<String, dynamic> _normalizeNotesDocument(Map<String, dynamic> source) {
    final normalized = Map<String, dynamic>.from(source);
    final chapter = source['chapter'];

    if (chapter is! Map) {
      normalized['definitions'] =
          _normalizeDefinitions(source['definitions']);
      normalized['key_points'] = _normalizeKeyPoints(
          source['key_points'] ?? source['keypoints']);
      normalized['formulas'] = _normalizeFormulas(source['formulas']);
      normalized['tables'] = _normalizeTables(source['tables']);
      normalized['diagrams'] = _normalizeDiagrams(source['diagrams']);
      normalized['sections'] = _asList(source['sections'])
          .whereType<Map>()
          .map((section) => _normalizeSection(section))
          .toList();
      final normalizedExercises = _normalizeExercises(
          source['exercises'] ?? source['practice_questions']);
      normalized['exercises'] = normalizedExercises;
      normalized['answers'] = _extractAnswers(source, normalizedExercises);
      return normalized;
    }

    final chapterMap = Map<String, dynamic>.from(chapter);
    normalized['chapter_title'] =
        chapterMap['chapter_title'] ?? source['title'];
    normalized['chapter_subtitle'] =
        chapterMap['chapter_subtitle'] ?? source['subtitle'];
    normalized['summary'] = chapterMap['chapter_introduction'] ??
        chapterMap['chapter_summary'] ??
        chapterMap['summary'] ??
        source['summary'];
    normalized['definitions'] =
        _normalizeDefinitions(chapterMap['definitions']);
    normalized['key_points'] = _normalizeKeyPoints(
        chapterMap['key_points'] ?? chapterMap['keypoints']);
    normalized['formulas'] = _normalizeFormulas(chapterMap['formulas']);
    normalized['tables'] = _normalizeTables(chapterMap['tables']);
    normalized['diagrams'] = _normalizeDiagrams(chapterMap['diagrams']);
    normalized['sections'] = _asList(chapterMap['sections'])
        .whereType<Map>()
        .map((section) => _normalizeSection(section))
        .toList();
    final normalizedExercises = _normalizeExercises(
        chapterMap['exercises'] ?? source['exercises']);
    normalized['exercises'] = normalizedExercises;
    normalized['answers'] = _extractAnswers(chapterMap, normalizedExercises);
    return normalized;
  }

  Map<String, dynamic> _normalizeSection(Map<dynamic, dynamic> raw) {
    final section = Map<String, dynamic>.from(raw);
    final paragraphs = <dynamic>[];
    final introduction = raw['section_introduction'];
    if (introduction != null &&
        introduction.toString().trim().isNotEmpty) {
      paragraphs.add(introduction.toString());
    }
    for (final paragraph in _asList(raw['paragraphs'])) {
      paragraphs.add(paragraph);
    }

    final subsections = <Map<String, dynamic>>[];
    for (final rawSub in _asList(raw['subsections'])) {
      if (rawSub is! Map) continue;
      final sub = Map<String, dynamic>.from(rawSub);
      sub['title'] = rawSub['subtitle'] ??
          rawSub['subsection_title'] ??
          rawSub['title'] ??
          rawSub['heading'];
      sub['paragraphs'] = _asList(rawSub['paragraphs']);
      sub['definitions'] = _normalizeDefinitions(rawSub['definitions']);
      sub['key_points'] =
          _normalizeKeyPoints(rawSub['key_points'] ?? rawSub['keypoints']);
      sub['formulas'] = _normalizeFormulas(rawSub['formulas']);
      sub['tables'] = _normalizeTables(rawSub['tables']);
      sub['diagrams'] = _normalizeDiagrams(rawSub['diagrams']);
      subsections.add(sub);
    }

    section['title'] =
        raw['section_title'] ?? raw['title'] ?? raw['heading'];
    section['paragraphs'] = paragraphs;
    section['subsections'] = subsections;
    section['definitions'] = _normalizeDefinitions(raw['definitions']);
    section['key_points'] =
        _normalizeKeyPoints(raw['key_points'] ?? raw['keypoints']);
    section['formulas'] = _normalizeFormulas(raw['formulas']);
    section['tables'] = _normalizeTables(raw['tables']);
    section['diagrams'] = _normalizeDiagrams(raw['diagrams']);
    return section;
  }

  List<dynamic> _asList(dynamic value) => value is List ? value : const [];

  List<dynamic> _normalizeDefinitions(dynamic value) {
    return _asList(value).map((definition) {
      if (definition is List && definition.length >= 2) {
        return {
          'term': definition.first.toString(),
          'definition': definition.skip(1).join(' — '),
        };
      }
      return definition;
    }).toList();
  }

  List<dynamic> _normalizeKeyPoints(dynamic value) => _asList(value);

  List<dynamic> _normalizeFormulas(dynamic value) {
    return _asList(value).map((formula) {
      if (formula is List && formula.length >= 2) {
        return {
          'name': formula.first.toString(),
          'formula': formula[1].toString(),
          'description': formula.length > 2 ? formula[2].toString() : '',
        };
      }
      return formula;
    }).toList();
  }

  List<dynamic> _normalizeTables(dynamic value) {
    final tables = <Map<String, dynamic>>[];
    for (final table in _asList(value)) {
      if (table is Map) {
        tables.add(Map<String, dynamic>.from(table));
        continue;
      }
      if (table is List && table.isNotEmpty) {
        final rows = table
            .map((row) => row is List
                ? row.map((cell) => cell.toString()).toList()
                : [row.toString()])
            .toList();
        tables.add({
          'headers': rows.first,
          'rows': rows.skip(1).toList(),
        });
      }
    }
    return tables;
  }

  List<dynamic> _normalizeDiagrams(dynamic value) {
    return _asList(value).map((diagram) {
      if (diagram is! Map) return diagram;
      final normalized = Map<String, dynamic>.from(diagram);
      normalized['title'] = diagram['diagram_title'] ??
          diagram['title'] ??
          'Diagram';
      final data = diagram['diagram_data'];
      if (data is Map) {
        normalized['steps'] = data.entries
            .map((entry) {
              final entryValue = entry.value;
              final text = entryValue is List
                  ? entryValue.map((item) => item.toString()).join(', ')
                  : entryValue.toString();
              return '${entry.key}: $text';
            })
            .toList();
      } else if (data is List) {
        normalized['steps'] = data;
      }
      if (normalized['description'] == null &&
          diagram['diagram_type'] != null) {
        normalized['description'] =
            'Type: ${diagram['diagram_type']}';
      }
      return normalized;
    }).toList();
  }

  List<Map<String, dynamic>> _normalizeExercises(dynamic value) {
    return _asList(value)
        .whereType<Map>()
        .map((exercise) => Map<String, dynamic>.from(exercise))
        .toList();
  }

  List<dynamic> _extractAnswers(
    Map<String, dynamic> source,
    List<Map<String, dynamic>> exercises,
  ) {
    final explicit = source['answers'] ??
        source['solutions'] ??
        source['exercise_answers'];
    if (explicit is List && explicit.isNotEmpty) return explicit;

    return exercises
        .where((exercise) => exercise['answer'] != null)
        .map((exercise) => {
              'answer': exercise['answer'].toString(),
              'explanation': exercise['explanation']?.toString() ?? '',
            })
        .toList();
  }

  // --- WIDGET BUILDERS FOR PDF ---

  pw.Widget _buildHeader(String title, PdfColor color, pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'ACADIA LEARNING',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(
            title,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Protected Educational Content • Not for redistribution',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTitleBanner({
    required String title,
    String? subtitle,
    required PdfColor primaryColor,
    required PdfColor accentColor,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ACADIA DIGITAL EDUCATION',
            style: pw.TextStyle(
              color: PdfColor.fromHex('#93C5FD'),
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            title,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (subtitle != null && subtitle.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(
                color: PdfColors.grey300,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildSectionHeader(String title, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(left: 8, top: 4, bottom: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: accentColor, width: 3.5)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _buildSummaryCard(dynamic summary, PdfColor accentColor, PdfColor bgColor) {
    final items = <String>[];
    if (summary is List) {
      items.addAll(summary.map((e) => e.toString()));
    } else if (summary is String) {
      items.add(summary);
    } else if (summary is Map) {
      items.addAll(summary.values.map((e) => e.toString()));
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: accentColor, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CHAPTER SUMMARY',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
              letterSpacing: 1.0,
            ),
          ),
          pw.SizedBox(height: 6),
          ...items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: pw.TextStyle(color: accentColor, fontWeight: pw.FontWeight.bold)),
                    pw.Expanded(
                      child: pw.Text(item, style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  pw.Widget _buildDefinitionsList(
    List<dynamic> definitions,
    PdfColor primaryColor,
    PdfColor bgColor,
    PdfColor borderColor,
  ) {
    return pw.Column(
      children: definitions.map((def) {
        String term = '';
        String description = '';
        if (def is Map) {
          term = def['term']?.toString() ?? def['title']?.toString() ?? def['name']?.toString() ?? '';
          description = def['definition']?.toString() ?? def['meaning']?.toString() ?? def['description']?.toString() ?? '';
        } else if (def is List && def.length >= 2) {
          term = def.first.toString();
          description = def.skip(1).map((e) => e.toString()).join(' — ');
        } else if (def is String) {
          final parts = def.split(':');
          term = parts.first.trim();
          description = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';
        }

        return pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(bottom: 6),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: bgColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(color: borderColor, width: 0.5),
          ),
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: '$term: ',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                    fontSize: 9.5,
                  ),
                ),
                pw.TextSpan(
                  text: description,
                  style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey800),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildKeyPointsList(List<dynamic> points, PdfColor primaryColor, PdfColor bgColor) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: points.map((p) {
          final text = p is Map ? (p['point'] ?? p['text'] ?? p.toString()) : p.toString();
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 5,
                  height: 5,
                  margin: const pw.EdgeInsets.only(top: 4, right: 6),
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(text, style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.3)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _buildFormulasList(
    List<dynamic> formulas,
    PdfColor primaryColor,
    PdfColor bgColor,
    PdfColor borderColor,
  ) {
    return pw.Column(
      children: formulas.map((f) {
        String name = '';
        String formula = '';
        String desc = '';
        if (f is Map) {
          name = f['name']?.toString() ?? f['title']?.toString() ?? '';
          formula = f['formula']?.toString() ?? f['equation']?.toString() ?? '';
          desc = f['description']?.toString() ?? f['variables']?.toString() ?? '';
        } else if (f is String) {
          formula = f;
        }

        return pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#EFF6FF'),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(color: PdfColor.fromHex('#BFDBFE'), width: 0.8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (name.isNotEmpty)
                pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              pw.SizedBox(height: 4),
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  formula,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.black,
                  ),
                ),
              ),
              if (desc.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  desc,
                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildTable(Map<String, dynamic> table, PdfColor primaryColor, PdfColor borderColor) {
    final title = table['title']?.toString();
    final headers = (table['headers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        (table['columns'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [];
    final rawRows = table['rows'] as List<dynamic>? ?? [];

    final rows = <List<String>>[];
    for (final r in rawRows) {
      if (r is List) {
        rows.add(r.map((e) => e.toString()).toList());
      } else if (r is Map) {
        rows.add(r.values.map((e) => e.toString()).toList());
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (title != null && title.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              title,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryColor),
            ),
          ),
        if (headers.isNotEmpty || rows.isNotEmpty)
          pw.TableHelper.fromTextArray(
            headers: headers.isNotEmpty ? headers : null,
            data: rows,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8.5,
            ),
            headerDecoration: pw.BoxDecoration(color: primaryColor),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 22,
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
            ),
            oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8FAFC')),
          ),
      ],
    );
  }

  pw.Widget _buildDiagram(
    Map<String, dynamic> diagram,
    PdfColor primaryColor,
    PdfColor bgColor,
    PdfColor borderColor,
  ) {
    final title = diagram['title']?.toString() ?? 'Diagram / Workflow';
    final desc = diagram['description']?.toString() ?? '';
    final steps = diagram['steps'] as List<dynamic>? ??
        diagram['events'] as List<dynamic>? ??
        diagram['nodes'] as List<dynamic>? ??
        [];

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: borderColor, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryColor),
          ),
          if (desc.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(desc, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
          ],
          if (steps.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            ...steps.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final s = entry.value;
              final text = s is Map ? (s['label'] ?? s['title'] ?? s['text'] ?? s.toString()) : s.toString();
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 16,
                      height: 16,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                      child: pw.Text(
                        '$idx',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.3)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  List<pw.Widget> _buildSection(
    Map<String, dynamic> section, {
    required PdfColor primaryColor,
    required PdfColor accentColor,
    required PdfColor secondaryColor,
    required PdfColor cardBg,
    required PdfColor borderCol,
  }) {
    final widgets = <pw.Widget>[];

    final title = section['title']?.toString() ?? section['heading']?.toString();
    if (title != null && title.isNotEmpty) {
      widgets.add(_buildSectionHeader(title, accentColor));
      widgets.add(pw.SizedBox(height: 6));
    }

    final paragraphs = section['paragraphs'] as List<dynamic>? ??
        section['content'] as List<dynamic>? ??
        (section['text'] != null ? [section['text']] : []);

    for (final p in paragraphs) {
      if (p is String) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(p, style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.4)),
        ));
      } else if (p is Map) {
        final text = p['text']?.toString() ?? p.toString();
        final bold = p['bold'] == true;
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 9.5,
              lineSpacing: 1.4,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ));
      }
    }

    // Section-level definitions
    final defs = section['definitions'] as List<dynamic>? ?? [];
    if (defs.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 4));
      widgets.add(_buildDefinitionsList(defs, primaryColor, cardBg, borderCol));
    }

    // Section-level formulas
    final forms = section['formulas'] as List<dynamic>? ?? [];
    if (forms.isNotEmpty) {
      widgets.add(pw.SizedBox(height: 4));
      widgets.add(_buildFormulasList(forms, primaryColor, cardBg, borderCol));
    }

    // Section-level tables
    final tables = section['tables'] as List<dynamic>? ?? [];
    for (final t in tables) {
      if (t is Map) {
        widgets.add(pw.SizedBox(height: 4));
        widgets.add(_buildTable(t.cast<String, dynamic>(), primaryColor, borderCol));
      }
    }

    // Section-level diagrams
    final diagrams = section['diagrams'] as List<dynamic>? ?? [];
    for (final d in diagrams) {
      if (d is Map) {
        widgets.add(pw.SizedBox(height: 4));
        widgets.add(_buildDiagram(
            d.cast<String, dynamic>(), primaryColor, cardBg, borderCol));
      }
    }

    // Subsections
    final subsections = section['subsections'] as List<dynamic>? ?? [];
    for (final sub in subsections) {
      if (sub is Map) {
        final subMap = sub.cast<String, dynamic>();
        final subTitle = subMap['title']?.toString() ?? subMap['heading']?.toString();
        if (subTitle != null && subTitle.isNotEmpty) {
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6, bottom: 4),
            child: pw.Text(
              subTitle,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: secondaryColor),
            ),
          ));
        }

        final subParas = subMap['paragraphs'] as List<dynamic>? ??
            subMap['content'] as List<dynamic>? ??
            (subMap['text'] != null ? [subMap['text']] : []);
        for (final sp in subParas) {
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(sp.toString(), style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.35)),
          ));
        }

        final subDefs = subMap['definitions'] as List<dynamic>? ?? [];
        if (subDefs.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 4));
          widgets.add(_buildDefinitionsList(subDefs, primaryColor, cardBg, borderCol));
        }

        final subPoints = subMap['key_points'] as List<dynamic>? ?? [];
        if (subPoints.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 4));
          widgets.add(_buildKeyPointsList(subPoints, primaryColor, cardBg));
        }

        final subFormulas = subMap['formulas'] as List<dynamic>? ?? [];
        if (subFormulas.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 4));
          widgets.add(_buildFormulasList(subFormulas, primaryColor, cardBg, borderCol));
        }

        final subTables = subMap['tables'] as List<dynamic>? ?? [];
        for (final t in subTables) {
          if (t is Map) {
            widgets.add(pw.SizedBox(height: 4));
            widgets.add(
                _buildTable(t.cast<String, dynamic>(), primaryColor, borderCol));
          }
        }

        final subDiagrams = subMap['diagrams'] as List<dynamic>? ?? [];
        for (final d in subDiagrams) {
          if (d is Map) {
            widgets.add(pw.SizedBox(height: 4));
            widgets.add(_buildDiagram(
                d.cast<String, dynamic>(), primaryColor, cardBg, borderCol));
          }
        }
      }
    }

    return widgets;
  }

  pw.Widget _buildExercises(
    List<dynamic> exercises,
    PdfColor primaryColor,
    PdfColor bgColor,
    PdfColor borderColor,
  ) {
    return pw.Column(
      children: exercises.asMap().entries.map((entry) {
        final idx = entry.key + 1;
        final ex = entry.value;
        String qText = '';
        List<String> options = [];

        if (ex is Map) {
          qText = ex['question']?.toString() ?? ex['text']?.toString() ?? '';
          final opts = ex['options'];
          if (opts is List) {
            options = opts.map((e) => e.toString()).toList();
          } else if (opts is Map) {
            options = opts.entries.map((e) => '${e.key}. ${e.value}').toList();
          }
        } else if (ex is String) {
          qText = ex;
        }

        return pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: bgColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            border: pw.Border.all(color: borderColor, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Q$idx: $qText',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
              ),
              if (options.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                ...options.map((opt) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 12, top: 2),
                      child: pw.Text(opt, style: const pw.TextStyle(fontSize: 8.5)),
                    )),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildAnswers(
    List<dynamic> answers,
    PdfColor primaryColor,
    PdfColor bgColor,
    PdfColor borderColor,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F0FDF4'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColor.fromHex('#BBF7D0'), width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SOLUTION KEY & EXPLANATIONS',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#166534'),
            ),
          ),
          pw.SizedBox(height: 6),
          ...answers.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final a = entry.value;
            String ans = '';
            String exp = '';

            if (a is Map) {
              ans = a['answer']?.toString() ?? a['correct']?.toString() ?? '';
              exp = a['explanation']?.toString() ?? a['solution']?.toString() ?? '';
            } else {
              ans = a.toString();
            }

            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: '$idx. ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                    ),
                    pw.TextSpan(
                      text: ans,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#15803D'),
                        fontSize: 9,
                      ),
                    ),
                    if (exp.isNotEmpty)
                      pw.TextSpan(
                        text: ' — $exp',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
