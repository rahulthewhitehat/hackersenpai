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
      print('Error getting student data: $e');
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
      print('Error getting course data: $e');
      rethrow;
    }
  }

  // Get all courses for a student
  Future<List<CourseModel>> getStudentCourses(List<String> courseIds) async {
    List<CourseModel> courses = [];
    try {
      for (String courseId in courseIds) {
        final course = await getCourseData(courseId);
        if (course != null) {
          courses.add(course);
        }
      }
      return courses;
    } catch (e) {
      print('Error getting student courses: $e');
      rethrow;
    }
  }

  // Get chapters for a course
  Stream<List<ChapterModel>> getChapters(String courseId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .collection('chapters')
        .orderBy('order') // Add this line to sort by order
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
        .orderBy('order') // Add this line to sort by order
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VideoModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}