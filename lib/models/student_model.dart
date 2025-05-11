class StudentModel {
  final String uid;
  final String email;
  final String name;
  final String studentId;
  final List<String> subjects;

  StudentModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.studentId,
    required this.subjects,
  });

  factory StudentModel.fromMap(String uid, Map<String, dynamic> data) {
    return StudentModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      studentId: data['student_id'] ?? '',
      subjects: List<String>.from(data['subjects'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'student_id': studentId,
      'subjects': subjects,
    };
  }
}