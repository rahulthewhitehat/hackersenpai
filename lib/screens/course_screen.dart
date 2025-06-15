import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mrcavirtuals/screens/video_playlist_screen_windows.dart';
import 'package:provider/provider.dart';
import '../models/chapter_model.dart';
import '../providers/student_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/chapter_card.dart';
import 'video_playlist_screen.dart';

class CourseScreen extends StatelessWidget {
  final String courseId;

  const CourseScreen({
    super.key,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final course = studentProvider.courses.firstWhere(
          (c) => c.id == courseId,
      orElse: () => throw Exception('Course not found'),
    );
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          course.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course header
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(isDarkMode ? 0.03 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(isDarkMode ? 0.5 : 0.7),
                  blurRadius: 10,
                  offset: const Offset(-4, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                       Theme.of(context).colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(isDarkMode ? 0.2 : 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.menu_book,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Browse chapters',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chapters section title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              'Chapters',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Chapter list
          Expanded(
            child: StreamBuilder<List<ChapterModel>>(
              stream: studentProvider.getChapters(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 56,
                          color: Theme.of(context).colorScheme.error.withOpacity(0.8),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                }

                final chapters = snapshot.data!;

                if (chapters.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 72,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No chapters available',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later or contact admin',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: chapters.length,
                  padding: const EdgeInsets.only(top: 8, bottom: 32),
                  itemBuilder: (context, index) {
                    final chapter = chapters[index];
                    final isSelected = chapter.id == studentProvider.selectedChapterId;

                    return FutureBuilder<Map<String, int>>(
                      future: studentProvider.getChapterProgress(chapter.id),
                      builder: (context, progressSnapshot) {
                        double completionPercentage = 0.0;
                        if (progressSnapshot.hasData) {
                          final totalItems = progressSnapshot.data!['totalItems'] ?? 0;
                          final completedItems = progressSnapshot.data!['completedItems'] ?? 0;
                          completionPercentage = totalItems > 0 ? (completedItems / totalItems) * 100 : 0.0;
                        }

                        return Stack(
                          children: [
                            ChapterCard(
                              chapter: chapter,
                              isSelected: isSelected,
                              onTap: () {
                                studentProvider.selectChapter(chapter.id);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => Platform.isWindows
                                        ? WindowsVideoPlaylistScreen(
                                      courseId: courseId,
                                      chapterId: chapter.id,
                                    )
                                        : VideoPlaylistScreen(
                                      courseId: courseId,
                                      chapterId: chapter.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (progressSnapshot.hasData)
                              Positioned(
                                right: 24,
                                top: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${completionPercentage.toStringAsFixed(0)}%',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}