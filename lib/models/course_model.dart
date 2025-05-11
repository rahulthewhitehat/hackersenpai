class CourseModel {
  final String id;
  final String name;

  CourseModel({
    required this.id,
    required this.name,
  });

  factory CourseModel.fromMap(String id, Map<String, dynamic> data) {
    return CourseModel(
      id: id,
      name: data['name'] ?? id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}