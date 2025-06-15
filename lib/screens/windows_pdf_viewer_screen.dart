import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../widgets/floating_watermark.dart';

class WindowsPDFViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String noteName;
  final String noteDescription;
  final String watermarkText;

  const WindowsPDFViewerScreen({
    super.key,
    required this.pdfPath,
    required this.noteName,
    required this.noteDescription,
    required this.watermarkText,
  });

  @override
  _WindowsPDFViewerScreenState createState() => _WindowsPDFViewerScreenState();
}

class _WindowsPDFViewerScreenState extends State<WindowsPDFViewerScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  final PdfViewerController _pdfViewerController = PdfViewerController();

  @override
  void initState() {
    super.initState();
    // Verify PDF file exists and is accessible
    _validatePdfFile();
  }

  Future<void> _validatePdfFile() async {
    try {
      final file = File(widget.pdfPath);
      final exists = await file.exists();
      if (!exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'PDF file not found at ${widget.pdfPath}';
        });
        return;
      }
      // Verify file is not empty
      final stat = await file.stat();
      if (stat.size == 0) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'PDF file is empty';
        });
        return;
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error validating PDF file: $e');
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error accessing PDF file: $e';
      });
    }
  }

  @override
  void dispose() {
    try {
      _pdfViewerController.dispose();
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing PDF viewer controller: $e');
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.noteName,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading PDF...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            )
          else if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 72,
                    color: colorScheme.error.withOpacity(0.8),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            SfPdfViewer.file(
              File(widget.pdfPath),
              controller: _pdfViewerController,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              enableDoubleTapZooming: true,
              onDocumentLoaded: (details) {
                if (kDebugMode) {
                  print('PDF loaded successfully: ${widget.pdfPath}');
                }
                setState(() {
                  _isLoading = false;
                });
              },
              onDocumentLoadFailed: (details) {
                if (kDebugMode) {
                  print('Failed to load PDF: ${details.description}');
                }
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'Failed to load PDF: ${details.description}';
                });
              },
            ),
          Positioned.fill(
            child: FloatingWatermark(
              text: widget.watermarkText,
              opacity: 0.2,
              constrainToPlayer: true,
            ),
          ),
        ],
      ),
    );
  }
}