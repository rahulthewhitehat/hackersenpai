class CourseModel {
  final String id;
  final String name;
  final String? expiryDate; // Added expiry date field

  CourseModel({
    required this.id,
    required this.name,
    this.expiryDate,
  });

  factory CourseModel.fromMap(String id, Map<String, dynamic> data) {
    return CourseModel(
      id: id,
      name: data['name'] ?? id,
      expiryDate: null, // Will be set from StudentProvider
    );
  }

  // Create a copy of the course model with expiry date
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