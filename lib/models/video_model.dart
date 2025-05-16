library;

class VideoModel {
  final String id;
  final String name;
  final String description;
  final String link;
  final String courseId;
  final String chapterId;
  final int order;
  final bool completed; // Field to track completion status

  VideoModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.link,
    required this.courseId,
    required this.chapterId,
    required this.order,
    this.completed = false, required String videoId,
  });

  factory VideoModel.fromMap(String id, Map<String, dynamic> map) {
    // Ensure link is a string, handle potential type issues
    final rawLink = map['link'];
    final String link = rawLink is String ? rawLink : rawLink?.toString() ?? '';

    return VideoModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      link: link,
      courseId: map['course_id'] ?? '',
      chapterId: map['chapter_id'] ?? '',
      order: map['order'] is int ? map['order'] : int.tryParse(map['order']?.toString() ?? '0') ?? 0,
      completed: map['completed'] ?? false, videoId: '',
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

  // Method to extract video ID from YouTube link
  String get videoId {
    try {
      final uri = Uri.parse(link);
      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        // For standard YouTube links like https://www.youtube.com/watch?v=yYX4bvQSqbo
        if (uri.queryParameters.containsKey('v')) {
          return uri.queryParameters['v']!;
        }
        // For youtu.be links like https://youtu.be/yYX4bvQSqbo
        else if (uri.pathSegments.isNotEmpty) {
          return uri.pathSegments.first;
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  // URL for embedded player
  String get embedUrl {
    final id = videoId;
    if (id.isNotEmpty) {
      return 'https://www.youtube.com/embed/$id?autoplay=1';
    }
    return link;
  }
}