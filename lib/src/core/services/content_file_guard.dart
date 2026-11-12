import 'dart:convert';
import 'dart:io';

/// Validation helpers for educational content files.
///
/// GitHub can return a small text "Git LFS pointer" for files that are stored
/// in Git LFS even though the URL still ends in `.pdf`. Such a file is not a
/// document and must never be handed to a PDF renderer or cached as valid.
class ContentFileGuard {
  ContentFileGuard._();

  static const String gitLfsPointerPrefix =
      'version https://git-lfs.github.com/spec/v1';

  static const int _pdfMagicLength = 5;

  static bool isPdfBytes(List<int> bytes) {
    if (bytes.length < _pdfMagicLength) return false;
    return bytes[0] == 0x25 && // %
        bytes[1] == 0x50 && // P
        bytes[2] == 0x44 && // D
        bytes[3] == 0x46 && // F
        bytes[4] == 0x2D; // -
  }

  static bool isGitLfsPointerBytes(List<int> bytes) {
    if (bytes.isEmpty) return false;
    final prefix = utf8.decode(
      bytes.take(128).toList(),
      allowMalformed: true,
    );
    return prefix.trimLeft().startsWith(gitLfsPointerPrefix);
  }

  static bool isGitLfsPointerText(String text) {
    return text.trimLeft().startsWith(gitLfsPointerPrefix);
  }

  static Future<bool> isPdfFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      final handle = await file.open();
      try {
        final bytes = await handle.read(_pdfMagicLength);
        return isPdfBytes(bytes);
      } finally {
        await handle.close();
      }
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isGitLfsPointerFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      final handle = await file.open();
      try {
        final bytes = await handle.read(128);
        return isGitLfsPointerBytes(bytes);
      } finally {
        await handle.close();
      }
    } catch (_) {
      return false;
    }
  }

  /// Converts a raw.githubusercontent.com URL to the media endpoint that
  /// serves the actual Git LFS object. Returns null for other hosts.
  static String? gitLfsMediaUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host != 'raw.githubusercontent.com') return null;
    final segments = uri.pathSegments;
    if (segments.length < 4) return null;
    return Uri(
      scheme: 'https',
      host: 'media.githubusercontent.com',
      pathSegments: ['media', ...segments],
    ).toString();
  }
}
