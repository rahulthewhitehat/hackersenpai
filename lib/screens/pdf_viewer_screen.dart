import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../widgets/floating_watermark.dart';

class PDFViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String noteName;
  final String noteDescription;
  final String watermarkText;

  const PDFViewerScreen({
    super.key,
    required this.pdfPath,
    required this.noteName,
    required this.noteDescription,
    required this.watermarkText,
  });

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Verify PDF file exists
    File(widget.pdfPath).exists().then((exists) {
      if (!exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'PDF file not found';
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    });
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
            PDFView(
              filePath: widget.pdfPath,
              enableSwipe: true,
              swipeHorizontal: false, // Vertical scrolling
              autoSpacing: false,
              pageFling: true,
              fitPolicy: FitPolicy.WIDTH, // Fit page to screen width
              onError: (error) {
                setState(() {
                  _errorMessage = 'Failed to load PDF: $error';
                });
              },
              onRender: (_pages) {
                setState(() {
                  _isLoading = false;
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