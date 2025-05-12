import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chapter_model.dart';
import '../providers/student_provider.dart';
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
    final course = studentProvider.courses.firstWhere(
          (c) => c.id == courseId,
      orElse: () => throw Exception('Course not found'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(course.name),
        centerTitle: true,
        elevation: 1,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course header
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu_book,
                        color: Colors.blue,
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
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Browse chapters below',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chapters section title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Chapters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
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
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
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
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No chapters available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: chapters.length,
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemBuilder: (context, index) {
                    final chapter = chapters[index];
                    final isSelected = chapter.id == studentProvider.selectedChapterId;

                    return ChapterCard(
                      chapter: chapter,
                      isSelected: isSelected,
                      onTap: () {
                        studentProvider.selectChapter(chapter.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoPlaylistScreen(
                              courseId: courseId,
                              chapterId: chapter.id,
                            ),
                          ),
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