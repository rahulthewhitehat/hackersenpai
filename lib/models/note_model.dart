/// Note Model
library;

class NoteModel {
  final String id;
  final String name;
  final String description;
  final String link;
  final String courseId;
  final String chapterId;
  final int order;
  final bool completed;

  NoteModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.link,
    required this.courseId,
    required this.chapterId,
    required this.order,
    this.completed = false,
  });

  factory NoteModel.fromMap(String id, Map<String, dynamic> map) {
    return NoteModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      link: map['link'] is String ? map['link'] : map['link']?.toString() ?? '',
      courseId: map['course_id'] ?? '',
      chapterId: map['chapter_id'] ?? '',
      order: map['order'] is int ? map['order'] : int.tryParse(map['order']?.toString() ?? '0') ?? 0,
      completed: map['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'link': link,
      'course_id': courseId,
      'chapter_id': chapterId,
      'order': order,
      'completed': completed,
    };
  }
}