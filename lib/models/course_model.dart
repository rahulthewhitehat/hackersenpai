/// Course Model
library;

class CourseModel {
  final String id;
  final String name;
  final String? expiryDate;

  CourseModel({
    required this.id,
    required this.name,
    this.expiryDate,
  });

  factory CourseModel.fromMap(String id, Map<String, dynamic> data) {
    return CourseModel(
      id: id,
      name: data['name'] ?? id,
      expiryDate: null,
    );
  }

  // Creating a copy of the course model with expiry date
  CourseModel copyWithExpiryDate(String? expiryDate) {
    return CourseModel(
      id: id,
      name: name,
      expiryDate: expiryDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}