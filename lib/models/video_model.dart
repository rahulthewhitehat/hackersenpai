class VideoModel {
  final String id;
  final String name;
  final String description;
  final String link;
  final String courseId;
  final String chapterId;
  final int order; // Add this field

  VideoModel({
    required this.id,
    required this.name,
    required this.description,
    required this.link,
    required this.courseId,
    required this.chapterId,
    required this.order, // Add to constructor
  });

  factory VideoModel.fromMap(String id, Map<String, dynamic> data) {
    return VideoModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      link: data['link'] ?? '',
      courseId: data['course_id'] ?? '',
      chapterId: data['chapter_id'] ?? '',
      order: data['order'] ?? 0, // Add to fromMap
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'link': link,
      'course_id': courseId,
      'chapter_id': chapterId,
    };
  }

  // Method to extract video ID from YouTube link
  // In VideoModel class, replace the videoId getter with this:
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

  // URL for web browser viewing
  String get browserUrl {
    final id = videoId;
    if (id.isNotEmpty) {
      return 'https://www.youtube.com/watch?v=$id';
    }
    return link;
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
