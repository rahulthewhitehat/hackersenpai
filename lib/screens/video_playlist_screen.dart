import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pod_player/pod_player.dart';
import 'package:provider/provider.dart';
import '../models/chapter_model.dart';
import '../models/video_model.dart';
import '../providers/student_provider.dart';
import '../widgets/video_list_item.dart';
import '../widgets/floating_watermark.dart';

class VideoPlaylistScreen extends StatefulWidget {
  final String courseId;
  final String chapterId;

  const VideoPlaylistScreen({
    Key? key,
    required this.courseId,
    required this.chapterId,
  }) : super(key: key);

  @override
  _VideoPlaylistScreenState createState() => _VideoPlaylistScreenState();
}

class _VideoPlaylistScreenState extends State<VideoPlaylistScreen> {
  late PodPlayerController _controller;
  bool _isInitialized = false;
  VideoModel? _currentVideo;
  ChapterModel? _currentChapter;
  bool _isLoading = true;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });

    // Lock to portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);

    // Find current chapter
    final chaptersStream = studentProvider.getChapters();
    if (chaptersStream != null) {
      final chapters = await chaptersStream.first;
      _currentChapter = chapters.firstWhere(
            (c) => c.id == widget.chapterId,
        orElse: () => throw Exception('Chapter not found'),
      );
    }

    // Get videos
    final videosStream = studentProvider.getVideos();
    if (videosStream != null) {
      final videos = await videosStream.first;
      if (videos.isNotEmpty) {
        _currentVideo = videos.first;
        await _initializeVideoPlayer(_currentVideo!);
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeVideoPlayer(VideoModel video) async {
    if (_isInitialized) {
      _controller.dispose();
    }

    try {
      final videoUrl = video.directUrl;
      _controller = PodPlayerController(
        playVideoFrom: PlayVideoFrom.network(videoUrl),
        podPlayerConfig: const PodPlayerConfig(
          autoPlay: true,
          isLooping: false,
          videoQualityPriority: [720, 360],
        ),
      )..initialise();

      _controller.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _currentVideo = video;
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video player: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading video: $e')),
        );
      }
    }
  }

  void _videoListener() {
    setState(() {
      _isFullScreen = _controller.isFullScreen;
    });
  }

  void _changeVideo(VideoModel video) {
    setState(() {
      _isLoading = true;
    });
    _initializeVideoPlayer(video).then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final student = studentProvider.student;

    // For responsive layout
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: isLandscape
          ? null // Hide AppBar in landscape mode
          : AppBar(
        title: Text(_currentChapter?.name ?? 'Video Player'),
        centerTitle: true,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isLandscape
          ? _buildLandscapeLayout(studentProvider, student?.email ?? '')
          : _buildPortraitLayout(studentProvider, student?.email ?? ''),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isInitialized || _currentVideo == null) {
      return const Center(
        child: Text('No video available'),
      );
    }

    return Stack(
      children: [
        PodVideoPlayer(
          controller: _controller,
          frameAspectRatio: 16 / 9,
          videoAspectRatio: 16 / 9,
          alwaysShowProgressBar: true,
        ),
        // Only show watermark if not in fullscreen
        if (!_isFullScreen && _currentVideo != null)
          IgnorePointer(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: FloatingWatermark(
                text: Provider.of<StudentProvider>(context).student?.email ?? '',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPortraitLayout(StudentProvider studentProvider, String watermarkText) {
    return Column(
      children: [
        // Video Player
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildVideoPlayer(),
        ),

        // Video info
        if (_currentVideo != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentVideo!.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentVideo!.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _currentVideo!.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Divider
        Divider(color: Colors.grey[300]),

        // Playlist title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.playlist_play, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Playlist',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                _currentChapter?.name ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Video list
        Expanded(
          child: StreamBuilder<List<VideoModel>>(
            stream: studentProvider.getVideos(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final videos = snapshot.data!;

              if (videos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.videocam_off,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No videos available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: videos.length,
                padding: const EdgeInsets.only(bottom: 24),
                itemBuilder: (context, index) {
                  final video = videos[index];
                  final isSelected = _currentVideo != null &&
                      _currentVideo!.id == video.id;

                  return VideoListItem(
                    video: video,
                    isSelected: isSelected,
                    onTap: () {
                      if (!isSelected) {
                        studentProvider.selectVideo(video);
                        _changeVideo(video);
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(StudentProvider studentProvider, String watermarkText) {
    return Row(
      children: [
        // Video player (main content)
        Expanded(
          flex: 3,
          child: _buildVideoPlayer(),
        ),

        // Video playlist (sidebar)
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.grey[100],
            child: Column(
              children: [
                // Chapter name header
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue[800],
                  width: double.infinity,
                  child: Text(
                    _currentChapter?.name ?? 'Videos',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Videos list
                Expanded(
                  child: StreamBuilder<List<VideoModel>>(
                    stream: studentProvider.getVideos(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final videos = snapshot.data!;

                      if (videos.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.videocam_off,
                                size: 36,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No videos',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: videos.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          final video = videos[index];
                          final isSelected = _currentVideo != null &&
                              _currentVideo!.id == video.id;

                          // Using a more compact video item for landscape mode
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: Colors.blue[50],
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.grey[300],
                              ),
                            ),
                            title: Text(
                              video.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              if (!isSelected) {
                                studentProvider.selectVideo(video);
                                _changeVideo(video);
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}