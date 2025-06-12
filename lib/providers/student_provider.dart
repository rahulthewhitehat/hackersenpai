import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../models/course_model.dart';
import '../models/chapter_model.dart';
import '../models/video_model.dart';
import '../models/note_model.dart';
import '../services/firebase_service.dart';

class StudentProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  StudentModel? _student;
  List<CourseModel> _courses = [];
  List<CourseModel> _activeCourses = [];
  String? _selectedCourseId;
  String? _selectedChapterId;
  VideoModel? _selectedVideo;
  NoteModel? _selectedNote;

  bool _isLoading = false;
  String _error = '';

  // Getters
  StudentModel? get student => _student;
  List<CourseModel> get courses => _activeCourses;
  String? get selectedCourseId => _selectedCourseId;
  String? get selectedChapterId => _selectedChapterId;
  VideoModel? get selectedVideo => _selectedVideo;
  NoteModel? get selectedNote => _selectedNote;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Initialize student data
  Future<bool> initializeStudent(String uid) async {
    try {
      _setLoading(true);

      final studentData = await _firestoreService.getStudentData(uid);
      if (studentData == null) {
        _setError('Student data not found');
        return false;
      }

      _student = studentData;

      _courses = await _firestoreService.getStudentCourses(_student!.subjects);

      _filterActiveCourses();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to load student data: $e');
      return false;
    }
  }

  void _filterActiveCourses() {
    final now = DateTime.now();
    _activeCourses = _courses.where((course) {
      if (course.expiryDate == null || course.expiryDate!.isEmpty) {
        return true;
      }

      try {
        final expiry = DateTime.parse(course.expiryDate!);
        return expiry.isAfter(now);
      } catch (e) {
        return true;
      }
    }).toList();

    notifyListeners();
  }

  void selectCourse(String courseId) {
    _selectedCourseId = courseId;
    _selectedChapterId = null;
    _selectedVideo = null;
    _selectedNote = null;
    notifyListeners();
  }

  void selectChapter(String chapterId) {
    _selectedChapterId = chapterId;
    _selectedVideo = null;
    _selectedNote = null;
    notifyListeners();
  }

  void selectVideo(VideoModel video) {
    _selectedVideo = video;
    _selectedNote = null;
    notifyListeners();
  }

  void selectNote(NoteModel note) {
    _selectedNote = note;
    _selectedVideo = null;
    notifyListeners();
  }

  Stream<List<ChapterModel>>? getChapters() {
    if (_selectedCourseId == null) return null;
    return _firestoreService.getChapters(_selectedCourseId!);
  }

  Stream<List<VideoModel>>? getVideos() {
    if (_selectedCourseId == null || _selectedChapterId == null) return null;
    return _firestoreService.getVideos(_selectedCourseId!, _selectedChapterId!);
  }

  Stream<List<NoteModel>>? getNotes() {
    if (_selectedCourseId == null || _selectedChapterId == null) return null;
    return _firestoreService.getNotes(_selectedCourseId!, _selectedChapterId!);
  }

  void resetSelection() {
    _selectedCourseId = null;
    _selectedChapterId = null;
    _selectedVideo = null;
    _selectedNote = null;
    notifyListeners();
  }

  void clearData() {
    _student = null;
    _courses = [];
    _activeCourses = [];
    resetSelection();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markVideoAsCompleted(VideoModel video) async {
    if (_student == null || _selectedCourseId == null) return;
    try {
      await _firestoreService.markVideoAsCompleted(
        uid: _student!.id,
        videoId: video.id,
        courseId: _selectedCourseId!,
        chapterId: video.chapterId,
      );
      if (_selectedVideo?.id == video.id) {
        _selectedVideo = VideoModel(
          id: video.id,
          name: video.name,
          description: video.description,
          videoId: video.videoId,
          chapterId: video.chapterId,
          completed: true,
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

  Future<void> unmarkVideoAsCompleted(VideoModel video) async {
    if (_student == null || _selectedCourseId == null) return;
    try {
      await _firestoreService.unmarkVideoAsCompleted(
        uid: _student!.id,
        videoId: video.id,
      );
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

  Future<void> markNoteAsCompleted(NoteModel note) async {
    if (_student == null || _selectedCourseId == null) return;
    try {
      await _firestoreService.markNoteAsCompleted(
        uid: _student!.id,
        noteId: note.id,
        courseId: _selectedCourseId!,
        chapterId: note.chapterId,
      );
      if (_selectedNote?.id == note.id) {
        _selectedNote = NoteModel(
          id: note.id,
          name: note.name,
          description: note.description,
          link: note.link,
          courseId: note.courseId,
          chapterId: note.chapterId,
          order: note.order,
          completed: true,
        );
      }
      notifyListeners();
    } catch (e) {
      // Handle error appropriately
    }
  }

  Future<void> unmarkNoteAsCompleted(NoteModel note) async {
    if (_student == null || _selectedCourseId == null) return;
    try {
      await _firestoreService.unmarkNoteAsCompleted(
        uid: _student!.id,
        noteId: note.id,
      );
      if (_selectedNote?.id == note.id) {
        _selectedNote = NoteModel(
          id: note.id,
          name: note.name,
          description: note.description,
          link: note.link,
          courseId: note.courseId,
          chapterId: note.chapterId,
          order: note.order,
          completed: false,
        );
      }
      notifyListeners();
    } catch (e) {
      // Handle error appropriately
    }
  }

  Stream<List<Map<String, dynamic>>>? getVideoProgress() {
    if (_student == null || _selectedCourseId == null) return null;
    return _firestoreService.streamVideoProgress(
      uid: _student!.id,
      courseId: _selectedCourseId!,
    );
  }

  Stream<List<Map<String, dynamic>>>? getNoteProgress() {
    if (_student == null || _selectedCourseId == null) return null;
    return _firestoreService.streamNoteProgress(
      uid: _student!.id,
      courseId: _selectedCourseId!,
    );
  }

  Future<Map<String, int>> getChapterProgress(String chapterId) async {
    if (_student == null || _selectedCourseId == null) {
      return {
        'totalItems': 0,
        'completedItems': 0,
      };
    }
    final progress = await _firestoreService.getChapterProgress(
      uid: _student!.id,
      courseId: _selectedCourseId!,
      chapterId: chapterId,
    );
    return progress;
  }
}