class ChapterModel {
  final String id;
  final String name;
  final String description;
  final String courseId;
  final int order; // Add this field

  ChapterModel({
    required this.id,
    required this.name,
    required this.description,
    required this.courseId,
    required this.order, // Add to constructor
  });

  factory ChapterModel.fromMap(String id, Map<String, dynamic> data) {
    return ChapterModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      courseId: data['course_id'] ?? '',
      order: data['order'] ?? 0, // Add to fromMap
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'course_id': courseId,
      'order': order, // Add to toMap
    };
  }
}