import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chapter_model.dart';
import '../models/student_model.dart';
import '../models/course_model.dart';
import '../models/video_model.dart';
import '../models/note_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get student data by UID
  Future<StudentModel?> getStudentData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return StudentModel.fromMap(uid, doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get course data by course ID
  Future<CourseModel?> getCourseData(String courseId) async {
    try {
      final doc = await _firestore.collection('courses').doc(courseId).get();
      if (doc.exists && doc.data() != null) {
        return CourseModel.fromMap(courseId, doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get all courses for a student using the subjects map
  Future<List<CourseModel>> getStudentCourses(Map<String, String> subjectsMap) async {
    List<CourseModel> courses = [];
    try {
      for (String courseId in subjectsMap.keys) {
        final course = await getCourseData(courseId);
        if (course != null) {
          final courseWithExpiry = course.copyWithExpiryDate(subjectsMap[courseId]);
          courses.add(courseWithExpiry);
        }
      }
      return courses;
    } catch (e) {
      rethrow;
    }
  }

  // Get chapters for a course
  Stream<List<ChapterModel>> getChapters(String courseId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('chapters')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChapterModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Get videos for a chapter
  Stream<List<VideoModel>> getVideos(String courseId, String chapterId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('chapters')
        .doc(chapterId)
        .collection('videos')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VideoModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Get notes for a chapter
  Stream<List<NoteModel>> getNotes(String courseId, String chapterId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('chapters')
        .doc(chapterId)
        .collection('notes')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NoteModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Mark a video as completed for a user
  Future<void> markVideoAsCompleted({
    required String uid,
    required String videoId,
    required String courseId,
    required String chapterId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('video_progress')
          .doc(videoId)
          .set({
        'videoId': videoId,
        'courseId': courseId,
        'chapterId': chapterId,
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // Mark a note as completed for a user
  Future<void> markNoteAsCompleted({
    required String uid,
    required String noteId,
    required String courseId,
    required String chapterId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('note_progress')
          .doc(noteId)
          .set({
        'noteId': noteId,
        'courseId': courseId,
        'chapterId': chapterId,
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // Unmark a video as completed
  Future<void> unmarkVideoAsCompleted({
    required String uid,
    required String videoId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('video_progress')
          .doc(videoId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // Unmark a note as completed
  Future<void> unmarkNoteAsCompleted({
    required String uid,
    required String noteId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('note_progress')
          .doc(noteId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // Stream video progress for a user in a specific course
  Stream<List<Map<String, dynamic>>> streamVideoProgress({
    required String uid,
    required String courseId,
  }) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('video_progress')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Stream note progress for a user in a specific course
  Stream<List<Map<String, dynamic>>> streamNoteProgress({
    required String uid,
    required String courseId,
  }) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('note_progress')
        .where('courseId', isEqualTo: courseId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Get total and completed video and note counts for a chapter
  Future<Map<String, int>> getChapterProgress({
    required String uid,
    required String courseId,
    required String chapterId,
  }) async {
    try {
      // Get total videos in the chapter
      final videoSnapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('chapters')
          .doc(chapterId)
          .collection('videos')
          .get();
      final totalVideos = videoSnapshot.docs.length;

      // Get completed videos in the chapter
      final videoProgressSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('video_progress')
          .where('chapterId', isEqualTo: chapterId)
          .where('completed', isEqualTo: true)
          .get();
      final completedVideos = videoProgressSnapshot.docs.length;

      // Get total notes in the chapter
      final noteSnapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('chapters')
          .doc(chapterId)
          .collection('notes')
          .get();
      final totalNotes = noteSnapshot.docs.length;

      // Get completed notes in the chapter
      final noteProgressSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('note_progress')
          .where('chapterId', isEqualTo: chapterId)
          .where('completed', isEqualTo: true)
          .get();
      final completedNotes = noteProgressSnapshot.docs.length;

      return {
        'totalVideos': totalVideos,
        'completedVideos': completedVideos,
        'totalNotes': totalNotes,
        'completedNotes': completedNotes,
        'totalItems': totalVideos + totalNotes,
        'completedItems': completedVideos + completedNotes,
      };
    } catch (e) {
      rethrow;
    }
  }
}