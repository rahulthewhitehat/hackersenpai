/// Student Model
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String id;
  final String studentId;
  final String name;
  final String email;
  final DateTime lastLogin;
  final Map<String, String> subjects;

  StudentModel({
    required this.id,
    required this.studentId,
    required this.name,
    required this.email,
    required this.lastLogin,
    required this.subjects,
  });

  factory StudentModel.fromMap(String id, Map<String, dynamic> data) {
    // Convert the subjects map
    Map<String, String> subjectsMap = {};
    if (data['subjects'] != null) {
      // Cast the Firestore map to the correct type
      Map<String, dynamic> rawSubjects = data['subjects'] as Map<String, dynamic>;
      rawSubjects.forEach((key, value) {
        subjectsMap[key] = value.toString();
      });
    }

    return StudentModel(
      id: id,
      studentId: data['student_id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      lastLogin: data['last_login'] != null
          ? (data['last_login'] as Timestamp).toDate()
          : DateTime.now(),
      subjects: subjectsMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'name': name,
      'email': email,
      'last_login': Timestamp.fromDate(lastLogin),
      'subjects': subjects,
    };
  }
}