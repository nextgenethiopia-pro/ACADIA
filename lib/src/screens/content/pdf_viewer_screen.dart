import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:acadia/src/core/services/offline_database.dart';
import 'package:acadia/src/core/constants/colors.dart';

class PdfViewerScreen extends StatefulWidget {
  final String contentId;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.contentId,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isCompleted = false;
  bool _isLoading = true;
  bool _isDownloaded = false;
  double _zoomLevel = 100.0;
  
  String _pdfTitle = '';
  String _fileSize = '';
  String? _localPath;
  
  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    setState(() => _isLoading = true);
    try {
      final offlineDb = OfflineDatabase.instance;
      final db = await offlineDb.database;

      final result = await db.query(
        'offline_content',
        where: 'content_id = ?',
        whereArgs: [widget.contentId],
      );

      if (result.isNotEmpty) {
        final data = result.first;
        final filePath = data['local_path'] as String;
        final file = File(filePath);

        if (await file.exists()) {
          final fileSizeBytes = data['file_size_bytes'] as int? ?? 0;

          if (mounted) {
            setState(() {
              _pdfTitle = data['title']?.toString() ?? widget.title;
              _localPath = filePath;
              _totalPages = data['page_count'] as int? ?? 1;
              _fileSize = _formatFileSize(fileSizeBytes);
              _isCompleted = data['is_completed'] == 1;
              _isDownloaded = true;
              _isLoading = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _isDownloaded = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading PDF: $e');
    }
  }

  Future<void> _markAsCompleted() async {
    try {
      final offlineDb = OfflineDatabase.instance;
      final db = await offlineDb.database;

      await db.update(
        'offline_content',
        {'is_completed': 1},
        where: 'content_id = ?',
        whereArgs: [widget.contentId],
      );

      if (mounted) {
        setState(() => _isCompleted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as completed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking as completed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark as completed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel + 25).clamp(50, 300);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel - 25).clamp(50, 300);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading PDF...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isDownloaded || _localPath == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.picture_as_pdf, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text(
                'PDF Not Downloaded',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Download the file first to view offline',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _pdfTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_fileSize.isNotEmpty)
              Text(
                _fileSize,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          // Zoom out
          IconButton(
            onPressed: _zoomOut,
            icon: const Icon(Icons.zoom_out),
            tooltip: 'Zoom out',
          ),
          // Zoom level indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_zoomLevel.toInt()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          // Zoom in
          IconButton(
            onPressed: _zoomIn,
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Zoom in',
          ),
        ],
      ),
      body: Column(
        children: [
          // Document info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.description, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Page $_currentPage of $_totalPages',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ],
                ),
                if (_isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Completed',
                          style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // PDF Viewer with pinch-to-zoom (actual PDF rendering)
          Expanded(
            child: SfPdfViewer.file(
              File(_localPath!),
              controller: _pdfController,
              scrollDirection: PdfScrollDirection.vertical,
              enableDoubleTapZooming: true,
              pageSpacing: 8,
              canShowScrollHead: true,
              canShowPaginationDialog: true,
              onPageChanged: (details) {
                if (mounted) {
                  setState(() {
                    _currentPage = details.newPageNumber;
                    _totalPages = _pdfController.pageCount;
                  });
                }
              },
              onDocumentLoaded: (details) {
                if (mounted) {
                  setState(() {
                    _totalPages = _pdfController.pageCount;
                  });
                }
              },
              onZoomLevelChanged: (details) {
                if (mounted) {
                  setState(() {
                    _zoomLevel = (details.newZoomLevel * 100).clamp(50, 300);
                  });
                }
              },
              pageLayoutMode: PdfPageLayoutMode.single,
              password: '',
            ),
          ),
          
          // Bottom bar with page navigation and mark complete button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page navigation buttons
                  Row(
                    children: [
                      // Previous page
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (_currentPage > 1) {
                              _pdfController.previousPage();
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _currentPage > 1 ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.chevron_left,
                              color: _currentPage > 1 ? AppColors.primary : Colors.grey[400],
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Page indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$_currentPage',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              ' / $_totalPages',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Next page
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (_currentPage < _totalPages) {
                              _pdfController.nextPage();
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _currentPage < _totalPages ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.chevron_right,
                              color: _currentPage < _totalPages ? AppColors.primary : Colors.grey[400],
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Mark as Completed button
                  ElevatedButton.icon(
                    onPressed: _isCompleted ? null : _markAsCompleted,
                    icon: Icon(
                      _isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                      size: 20,
                    ),
                    label: Text(
                      _isCompleted ? 'Completed' : 'Mark Complete',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCompleted ? Colors.green : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}