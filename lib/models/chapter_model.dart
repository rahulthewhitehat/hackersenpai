class ChapterModel {
  final String id;
  final String name;
  final String description;
  final String courseId;

  ChapterModel({
    required this.id,
    required this.name,
    required this.description,
    required this.courseId,
  });

  factory ChapterModel.fromMap(String id, Map<String, dynamic> data) {
    return ChapterModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      courseId: data['course_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'course_id': courseId,
    };
  }
}