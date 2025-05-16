import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chapter_model.dart';
import '../models/student_model.dart';
import '../models/course_model.dart';
import '../models/video_model.dart';

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
      //print('Error getting student data: $e');
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
      //print('Error getting course data: $e');
      rethrow;
    }
  }

  // Get all courses for a student using the subjects map
  Future<List<CourseModel>> getStudentCourses(Map<String, String> subjectsMap) async {
    List<CourseModel> courses = [];
    try {
      // For each subject in the map, get the course data
      for (String courseId in subjectsMap.keys) {
        final course = await getCourseData(courseId);
        if (course != null) {
          // Add the expiry date to the course
          final courseWithExpiry = course.copyWithExpiryDate(subjectsMap[courseId]);
          courses.add(courseWithExpiry);
        }
      }
      return courses;
    } catch (e) {
      //print('Error getting student courses: $e');
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
      //print('Error marking video as completed: $e');
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

  // Get total and completed video counts for a chapter
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
      final progressSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('video_progress')
          .where('chapterId', isEqualTo: chapterId)
          .where('completed', isEqualTo: true)
          .get();
      final completedVideos = progressSnapshot.docs.length;

      return {
        'totalVideos': totalVideos,
        'completedVideos': completedVideos,
      };
    } catch (e) {
      //print('Error getting chapter progress: $e');
      rethrow;
    }
  }

  Future<void> unmarkVideoAsCompleted({
    required String uid,
    required String videoId,
  }) async {
    try {
      // Delete the document to remove the completion status
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('video_progress')
          .doc(videoId)
          .delete();
    } catch (e) {
      //print('Error unmarking video as completed: $e');
      rethrow;
    }
  }
}