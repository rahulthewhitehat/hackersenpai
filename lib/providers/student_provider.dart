import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/course_model.dart';
import '../models/chapter_model.dart';
import '../models/video_model.dart';
import '../services/firebase_service.dart';

class StudentProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  StudentModel? _student;
  List<CourseModel> _courses = [];
  List<CourseModel> _activeCourses = [];
  String? _selectedCourseId;
  String? _selectedChapterId;
  VideoModel? _selectedVideo;

  bool _isLoading = false;
  String _error = '';

  // Getters
  StudentModel? get student => _student;
  List<CourseModel> get courses => _activeCourses;
  String? get selectedCourseId => _selectedCourseId;
  String? get selectedChapterId => _selectedChapterId;
  VideoModel? get selectedVideo => _selectedVideo;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Initialize student data
  Future<bool> initializeStudent(String uid) async {
    try {
      _setLoading(true);

      // Get student data
      final studentData = await _firestoreService.getStudentData(uid);
      if (studentData == null) {
        _setError('Student data not found');
        return false;
      }

      _student = studentData;

      // Get courses with expiry dates
      _courses = await _firestoreService.getStudentCourses(_student!.subjects);

      // Filter out expired courses
      _filterActiveCourses();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to load student data: $e');
      return false;
    }
  }

  // Filter active courses based on expiry date
  void _filterActiveCourses() {
    final now = DateTime.now();
    _activeCourses = _courses.where((course) {
      // If no expiry date, consider it as active
      if (course.expiryDate == null || course.expiryDate!.isEmpty) {
        return true;
      }

      try {
        // Parse the expiry date
        final expiry = DateTime.parse(course.expiryDate!);
        // Course is active if expiry date is in the future
        return expiry.isAfter(now);
      } catch (e) {
        // If parsing fails, consider as active
        return true;
      }
    }).toList();

    notifyListeners();
  }

  // Select a course
  void selectCourse(String courseId) {
    _selectedCourseId = courseId;
    _selectedChapterId = null;
    _selectedVideo = null;
    notifyListeners();
  }

  // Select a chapter
  void selectChapter(String chapterId) {
    _selectedChapterId = chapterId;
    _selectedVideo = null;
    notifyListeners();
  }

  // Select a video
  void selectVideo(VideoModel video) {
    _selectedVideo = video;
    notifyListeners();
  }

  // Get chapters stream
  Stream<List<ChapterModel>>? getChapters() {
    if (_selectedCourseId == null) return null;
    return _firestoreService.getChapters(_selectedCourseId!);
  }

  // Get videos stream
  Stream<List<VideoModel>>? getVideos() {
    if (_selectedCourseId == null || _selectedChapterId == null) return null;
    return _firestoreService.getVideos(_selectedCourseId!, _selectedChapterId!);
  }

  // Reset selection
  void resetSelection() {
    _selectedCourseId = null;
    _selectedChapterId = null;
    _selectedVideo = null;
    notifyListeners();
  }

  // Clear all student data (for logout)
  void clearData() {
    _student = null;
    _courses = [];
    _activeCourses = [];
    resetSelection();
  }

  // Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  // Mark a video as completed
  Future<void> markVideoAsCompleted(VideoModel video) async {
    if (_student == null || _selectedCourseId == null) return;
    try {
      await _firestoreService.markVideoAsCompleted(
        uid: _student!.id,
        videoId: video.id,
        courseId: _selectedCourseId!,
        chapterId: video.chapterId,
      );
      // Update the selected video if it's the one being marked
      if (_selectedVideo?.id == video.id) {
        _selectedVideo = VideoModel(
          id: video.id,
          name: video.name,
          description: video.description,
          videoId: video.videoId,
          chapterId: video.chapterId,
          completed: true, link: video.link,courseId: video.courseId, order: video.order,
        );
      }
      notifyListeners();
    } catch (e) {
      // Handle error appropriately
    }
  }

  Future<void> unmarkVideoAsCompleted(VideoModel video) async {
    if (_student == null || _selectedCourseId == null) return;
    try {
      await _firestoreService.unmarkVideoAsCompleted(
        uid: _student!.id,
        videoId: video.id,
      );
      // Update the selected video if it's the one being unmarked
      if (_selectedVideo?.id == video.id) {
        _selectedVideo = VideoModel(
          id: video.id,
          name: video.name,
          description: video.description,
          videoId: video.videoId,
          chapterId: video.chapterId,
          completed: false,
          link: video.link,
          courseId: video.courseId,
          order: video.order,
        );
      }
      notifyListeners();
    } catch (e) {
      // Handle error appropriately
    }
  }

  // Stream video progress for the current course
  Stream<List<Map<String, dynamic>>>? getVideoProgress() {
    if (_student == null || _selectedCourseId == null) return null;
    return _firestoreService.streamVideoProgress(
      uid: _student!.id,
      courseId: _selectedCourseId!,
    );
  }

  // Get chapter progress
  Future<Map<String, int>> getChapterProgress(String chapterId) async {
    if (_student == null || _selectedCourseId == null) {
      return {'totalVideos': 0, 'completedVideos': 0};
    }
    return await _firestoreService.getChapterProgress(
      uid: _student!.id,
      courseId: _selectedCourseId!,
      chapterId: chapterId,
    );
  }
}
