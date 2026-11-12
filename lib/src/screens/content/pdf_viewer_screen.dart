import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:acadia/src/local_database/isar_service.dart';
import 'package:acadia/src/core/constants/colors.dart';
import 'package:acadia/src/core/services/content_file_guard.dart';
import 'package:acadia/src/core/services/content_pdf_generator.dart';
import 'package:acadia/src/core/services/progress_tracking_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final String contentId;
  final String title;
  final String? downloadUrl;

  /// Original remote source, kept separately so a viewer opened from a local
  /// cache can still recover by downloading a fresh copy when Retry is tapped.
  final String? remoteUrl;

  const PdfViewerScreen({
    super.key,
    required this.contentId,
    required this.title,
    this.downloadUrl,
    this.remoteUrl,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  static const MethodChannel _securityChannel =
      MethodChannel('com.nextgenethiopia.acadia/security');

  final IsarService _isarService = IsarService.instance;
  final PdfViewerController _pdfController = PdfViewerController();

  bool _isLoading = true;
  bool _isDownloaded = false;
  String? _localPath;
  String? _downloadUrl;
  String? _remoteUrl;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isPdfLoaded = false;
  String? _errorMessage;

  // Reader Features
  bool _isDarkMode = false;
  List<Map<String, dynamic>> _highlights = [];
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _downloadUrl = widget.downloadUrl;
    _remoteUrl = widget.remoteUrl;
    _enableSecureWindow();
    _loadHighlights();
    _loadPdf();
  }

  @override
  void dispose() {
    if (_sessionStartTime != null) {
      final seconds = DateTime.now().difference(_sessionStartTime!).inSeconds;
      if (seconds >= 3) {
        ProgressTrackingService().recordStudyTime(seconds);
      }
    }
    _disableSecureWindow();
    _pdfController.dispose();
    super.dispose();
  }

  /// Enable Android FLAG_SECURE to prevent screenshots/recording
  Future<void> _enableSecureWindow() async {
    try {
      await _securityChannel.invokeMethod('enableSecure');
    } catch (e) {
      debugPrint('ℹ️ Security channel not supported or not on Android: $e');
    }
  }

  /// Disable Android FLAG_SECURE on dispose
  Future<void> _disableSecureWindow() async {
    try {
      await _securityChannel.invokeMethod('disableSecure');
    } catch (e) {
      debugPrint('ℹ️ Security channel clear error: $e');
    }
  }

  Future<void> _loadHighlights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('highlights_${widget.contentId}');
      if (data != null && data.isNotEmpty) {
        final decoded = json.decode(data);
        if (decoded is List) {
          setState(() {
            _highlights = List<Map<String, dynamic>>.from(decoded);
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading highlights: $e');
    }
  }

  Future<void> _saveHighlights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'highlights_${widget.contentId}',
        json.encode(_highlights),
      );
    } catch (e) {
      debugPrint('⚠️ Error saving highlights: $e');
    }
  }

  void _addHighlight() {
    showDialog(
      context: context,
      builder: (context) {
        final noteController = TextEditingController();
        String selectedColor = 'Yellow';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Highlight Page $_currentPage'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add a persistent highlight or study note for this page:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Important definition or formula',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Color: ', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      ...['Yellow', 'Green', 'Blue', 'Orange'].map((colorName) {
                        Color col;
                        switch (colorName) {
                          case 'Green':
                            col = Colors.green;
                            break;
                          case 'Blue':
                            col = Colors.blue;
                            break;
                          case 'Orange':
                            col = Colors.orange;
                            break;
                          default:
                            col = Colors.amber;
                        }
                        final isSel = selectedColor == colorName;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedColor = colorName);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: col,
                              shape: BoxShape.circle,
                              border: isSel
                                  ? Border.all(color: Colors.black87, width: 2)
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final note = noteController.text.trim();
                    setState(() {
                      _highlights.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'page': _currentPage,
                        'note': note.isNotEmpty ? note : 'Page $_currentPage Highlight',
                        'color': selectedColor,
                        'created_at': DateTime.now().toIso8601String(),
                      });
                    });
                    _saveHighlights();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Highlight saved for Page $_currentPage'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Highlight'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showHighlightsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Highlights & Notes (${_highlights.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              if (_highlights.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No highlights added yet.\nTap the highlight icon to save notes for pages.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _highlights.length,
                    itemBuilder: (context, index) {
                      final h = _highlights[index];
                      final page = h['page'] as int? ?? 1;
                      final note = h['note']?.toString() ?? '';
                      final colorName = h['color']?.toString() ?? 'Yellow';
                      Color markerColor;
                      switch (colorName) {
                        case 'Green':
                          markerColor = Colors.green;
                          break;
                        case 'Blue':
                          markerColor = Colors.blue;
                          break;
                        case 'Orange':
                          markerColor = Colors.orange;
                          break;
                        default:
                          markerColor = Colors.amber;
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: markerColor.withOpacity(0.2),
                          foregroundColor: markerColor,
                          child: Text('$page', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(note, style: const TextStyle(fontSize: 14)),
                        subtitle: Text('Page $page', style: const TextStyle(fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _highlights.removeAt(index);
                            });
                            _saveHighlights();
                            Navigator.pop(context);
                          },
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _pdfController.jumpToPage(page);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showJumpToPageDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '1 - $_totalPages',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text.trim());
              if (page != null && page >= 1 && page <= _totalPages) {
                Navigator.pop(context);
                _pdfController.jumpToPage(page);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  Future<String> _preparePdf(String? source, String? userId) {
    return ContentPdfGenerator().getOrGeneratePdf(
      contentId: widget.contentId,
      title: widget.title,
      downloadUrl: source,
      userId: userId,
    );
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid;

      // 1. Check local Isar record. A record alone is not proof: older builds
      // cached Git LFS pointer text as a .pdf, which crashes the renderer.
      if (userId != null) {
        final downloaded =
            await _isarService.getDownloadedContentById(widget.contentId, userId);
        if (downloaded != null && downloaded.contentPath != null) {
          final path = downloaded.contentPath!;
          final file = File(path);
          if (await file.exists() && await file.length() > 0) {
            if (path.toLowerCase().endsWith('.pdf')) {
              if (await ContentFileGuard.isPdfFile(path)) {
                setState(() {
                  _localPath = path;
                  _isDownloaded = true;
                  _isLoading = false;
                  _isPdfLoaded = true;
                });
                return;
              }
              debugPrint(
                  '🧹 Cached document is not a valid PDF; removing it: $path');
              await file.delete();
              await _isarService.deleteDownloadedContent(
                  widget.contentId, userId);
            }
          } else {
            if (await file.exists()) {
              await file.delete();
            }
            await _isarService.deleteDownloadedContent(
                widget.contentId, userId);
          }
        }
      }

      // 2. Generate or fetch PDF using ContentPdfGenerator. If the local
      // cache is unusable, retry from the original remote URL so Retry works
      // even when the viewer was opened from the offline chapter list.
      String resolvedPath;
      try {
        resolvedPath = await _preparePdf(_downloadUrl, userId);
      } on ContentPdfException catch (e) {
        final source = (_downloadUrl ?? '').trim();
        final remote = (_remoteUrl ?? '').trim();
        final canUseRemote = remote.startsWith('http://') ||
            remote.startsWith('https://');
        if (!canUseRemote || remote == source) rethrow;
        debugPrint('🔁 Local copy unusable ($e), retrying from: $remote');
        resolvedPath = await _preparePdf(remote, userId);
      }

      final file = File(resolvedPath);
      final isPdf = resolvedPath.toLowerCase().endsWith('.pdf') &&
          await ContentFileGuard.isPdfFile(resolvedPath);
      if (await file.exists() && await file.length() > 0 && isPdf) {
        setState(() {
          _localPath = resolvedPath;
          _isDownloaded = true;
          _isLoading = false;
          _isPdfLoaded = true;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'The document file could not be prepared. Please retry.';
      });
    } on ContentPdfException catch (e) {
      debugPrint('❌ Document preparation failed: ${e.message}');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      debugPrint('❌ Error in _loadPdf: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'The document could not be prepared. Check your connection and retry.';
        });
      }
    }
  }

  /// Syncfusion rejects files that pass the magic-byte check but are still
  /// unreadable. Remove the unusable copy so Retry can fetch a fresh one.
  Future<void> _discardUnreadablePdf() async {
    final path = _localPath;
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          debugPrint('🧹 Removed unreadable document: $path');
        }
      } catch (e) {
        debugPrint('⚠️ Could not remove unreadable document: $e');
      }
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _isarService.deleteDownloadedContent(widget.contentId, user.uid);
      } catch (e) {
        debugPrint('⚠️ Could not remove stale download record: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final fgColor = _isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(fontSize: 16, color: fgColor, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        elevation: 0.5,
        leading: IconButton(
          onPressed: () {
            _updateLastAccessed();
            context.pop();
          },
          icon: Icon(Icons.arrow_back, color: fgColor),
        ),
        actions: [
          // Theme Toggle (Light / Dark)
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: fgColor,
            ),
            tooltip: _isDarkMode ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            onPressed: () {
              setState(() => _isDarkMode = !_isDarkMode);
            },
          ),
          // Highlight Action
          IconButton(
            icon: Icon(Icons.border_color_outlined, color: fgColor),
            tooltip: 'Highlight Page',
            onPressed: _addHighlight,
          ),
          // View Saved Highlights
          IconButton(
            icon: Badge(
              isLabelVisible: _highlights.isNotEmpty,
              label: Text('${_highlights.length}'),
              child: Icon(Icons.bookmarks_outlined, color: fgColor),
            ),
            tooltip: 'View Highlights & Notes',
            onPressed: _showHighlightsSheet,
          ),
          if (_isDownloaded)
            IconButton(
              icon: Icon(Icons.delete_outline, color: fgColor),
              onPressed: _confirmDelete,
              tooltip: 'Delete from device',
            ),
        ],
      ),
      bottomNavigationBar: _isPdfLoaded && _totalPages > 0
          ? _buildBottomToolbar(bgColor, fgColor)
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _isDownloaded && _localPath != null
                  ? _buildPdfViewer()
                  : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildBottomToolbar(Color bgColor, Color fgColor) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous page
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: fgColor,
            onPressed: _currentPage > 1
                ? () => _pdfController.previousPage()
                : null,
          ),
          // Page jump indicator
          GestureDetector(
            onTap: _showJumpToPageDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Page $_currentPage of $_totalPages',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ),
          ),
          // Next page
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: fgColor,
            onPressed: _currentPage < _totalPages
                ? () => _pdfController.nextPage()
                : null,
          ),
          const VerticalDivider(width: 16, indent: 12, endIndent: 12),
          // Zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_out, size: 20),
            color: fgColor,
            tooltip: 'Zoom Out',
            onPressed: () {
              final newZoom = (_pdfController.zoomLevel - 0.25).clamp(1.0, 4.0);
              _pdfController.zoomLevel = newZoom;
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, size: 20),
            color: fgColor,
            tooltip: 'Zoom In',
            onPressed: () {
              final newZoom = (_pdfController.zoomLevel + 0.25).clamp(1.0, 4.0);
              _pdfController.zoomLevel = newZoom;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    Widget viewer = SfPdfViewer.file(
      File(_localPath!),
      controller: _pdfController,
      enableTextSelection: false, // Prevent copy/select
      canShowPageLoadingIndicator: true,
      canShowScrollHead: true,
      pageSpacing: 4,
      enableDoubleTapZooming: true,
      onPageChanged: (PdfPageChangedDetails details) {
        debugPrint('📄 PDF page changed: ${details.newPageNumber}');
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        final count = details.document.pages.count;
        debugPrint('✅ PDF document loaded: $count pages');
        setState(() {
          _isPdfLoaded = true;
          _totalPages = count;
          _currentPage = 1;
          _isLoading = false;
          _errorMessage = null;
        });
      },
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        debugPrint('❌ PDF load failed: ${details.error}');
        _discardUnreadablePdf();
        setState(() {
          _isPdfLoaded = false;
          _isLoading = false;
          _localPath = null;
          _isDownloaded = false;
          _totalPages = 0;
          _errorMessage =
              'The saved document could not be opened and was removed. Tap Retry to download it again.';
        });
      },
    );

    // Apply dark mode color filter if enabled
    if (_isDarkMode) {
      viewer = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          -1.0, 0.0, 0.0, 0.0, 255.0, //
          0.0, -1.0, 0.0, 0.0, 255.0, //
          0.0, 0.0, -1.0, 0.0, 255.0, //
          0.0, 0.0, 0.0, 1.0, 0.0, //
        ]),
        child: viewer,
      );
    }

    return viewer;
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Document',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An error occurred while preparing the content.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPdf,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document?'),
        content: const Text(
          'Remove this document from local storage? You can download or generate it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePdf();
    }
  }

  Future<void> _deletePdf() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (_localPath != null) {
        final file = File(_localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      await _isarService.deleteDownloadedContent(widget.contentId, user.uid);

      if (mounted) {
        setState(() {
          _isDownloaded = false;
          _localPath = null;
          _isPdfLoaded = false;
          _totalPages = 0;
          _currentPage = 0;
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Delete failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete this document. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateLastAccessed() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final record = await _isarService.getDownloadedContentById(
        widget.contentId,
        user.uid,
      );
      if (record != null) {
        record.lastAccessed = DateTime.now();
        await _isarService.saveDownloadedContent(record);
      }
    } catch (e) {
      debugPrint('⚠️ Error updating last accessed: $e');
    }
  }
}