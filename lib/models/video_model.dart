class VideoModel {
  final String id;
  final String name;
  final String description;
  final String link;
  final String courseId;
  final String chapterId;

  VideoModel({
    required this.id,
    required this.name,
    required this.description,
    required this.link,
    required this.courseId,
    required this.chapterId,
  });

  factory VideoModel.fromMap(String id, Map<String, dynamic> data) {
    return VideoModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      link: data['link'] ?? '',
      courseId: data['course_id'] ?? '',
      chapterId: data['chapter_id'] ?? '',
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

  // Method to extract video ID from Google Drive link
  String get videoId {
    if (link.contains('drive.google.com')) {
      final RegExp regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
      final match = regExp.firstMatch(link);
      if (match != null && match.groupCount >= 1) {
        return match.group(1)!;
      }
    }
    return '';
  }

  // Method to get direct playable URL for Google Drive videos
  String get directUrl {
    final id = videoId;
    if (id.isNotEmpty) {
      return 'https://drive.google.com/uc?export=download&id=$id';
    }
    return link;
  }
}