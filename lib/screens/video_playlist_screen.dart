import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import '../models/chapter_model.dart';
import '../models/video_model.dart';
import '../providers/student_provider.dart';
import '../widgets/video_list_item.dart';
import '../widgets/floating_watermark.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPlaylistScreen extends StatefulWidget {
  final String courseId;
  final String chapterId;

  const VideoPlaylistScreen({
    super.key,
    required this.courseId,
    required this.chapterId,
  });

  @override
  _VideoPlaylistScreenState createState() => _VideoPlaylistScreenState();
}

class _VideoPlaylistScreenState extends State<VideoPlaylistScreen> with WidgetsBindingObserver {
  late YoutubePlayerController _controller;
  VideoModel? _currentVideo;
  ChapterModel? _currentChapter;
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  bool _showPlaylistInLandscape = false;
  double _playlistWidth = 0.0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isInitialized) {
      _controller.dispose();
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Handle orientation changes without reloading the video
    if (_isInitialized && _currentVideo != null) {
      final orientation = MediaQuery.of(context).orientation;
      print('Orientation changed to: $orientation');
      // No need to reload the video, just update the UI
      setState(() {});
    }
  }

  Future<void> _initializeScreen() async {
    try {
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
          _currentVideo = studentProvider.selectedVideo ?? videos.first;

          // Initialize YouTube Player controller once
          _controller = YoutubePlayerController(
            initialVideoId: _currentVideo!.videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: true,
              mute: false,
              enableCaption: false,
              hideControls: false,
              controlsVisibleAtStart: false,
              disableDragSeek: false,
              loop: false,
              isLive: false,
              forceHD: true,
            ),
          );

          _isInitialized = true;
        } else {
          setState(() {
            _isError = true;
            _errorMessage = 'No videos available in this chapter';
          });
        }
      }
    } catch (e) {
      print('Error initializing screen: $e');
      setState(() {
        _isError = true;
        _errorMessage = 'Failed to load content: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _togglePlaylistVisibility() {
    setState(() {
      _showPlaylistInLandscape = !_showPlaylistInLandscape;
      _playlistWidth = _showPlaylistInLandscape ? 300.0 : 0.0;
    });
  }

  void _openInBrowser() async {
    if (_currentVideo == null || _currentVideo!.videoId.isEmpty) return;

    final url = Uri.parse(_currentVideo!.browserUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open video in browser')),
      );
    }
  }

  Future<void> _changeVideo(VideoModel video) async {
    if (_currentVideo?.id == video.id) return;

    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    studentProvider.selectVideo(video);

    setState(() {
      _isLoading = true;
      _currentVideo = video;
    });

    try {
      _controller.load(video.videoId);
      _controller.play();
    } catch (e) {
      print('Error changing video: $e');
      setState(() {
        _isError = true;
        _errorMessage = 'Failed to load video: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _retryPlayback() {
    if (_currentVideo != null) {
      setState(() {
        _isLoading = true;
      });
      _changeVideo(_currentVideo!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final student = studentProvider.student;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isError) {
      return Scaffold(
        appBar: AppBar(title: Text(_currentChapter?.name ?? 'Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _retryPlayback,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Use YoutubePlayerBuilder to properly handle orientation changes
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.blueAccent,
        onReady: () => setState(() {}),
      ),
      builder: (context, player) {

        if (isLandscape) {
          return Scaffold(
            body: Stack(
              children: [
                // Main YouTube player (full screen)
                Positioned.fill(
                  child: player,
                ),

                // Playlist toggle button
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.black54,
                    onPressed: _togglePlaylistVisibility,
                    child: Icon(
                      _showPlaylistInLandscape ? Icons.close : Icons.playlist_play,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Sliding playlist with close button in header
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  right: _playlistWidth - 300, // Slide from right
                  top: 0,
                  bottom: 0,
                  width: 300,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(-3, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Chapter name header with close button
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.blue[800],
                          width: double.infinity,
                          child: Row(
                            children: [
                              Expanded(
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
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: _togglePlaylistVisibility,
                              ),
                            ],
                          ),
                        ),

                        // Videos list
                        Expanded(
                          child: _buildVideoList(studentProvider),
                        ),
                      ],
                    ),
                  ),
                ),

                // Watermark
                Positioned.fill(
                  child: FloatingWatermark(
                    text: "${student?.email}\n${student?.studentId}",
                    opacity: 0.2,
                  ),
                ),
              ],
            ),
          );
        }

        // Portrait mode
        return Scaffold(
          appBar: AppBar(
            title: Text(_currentChapter?.name ?? 'Video Player'),
            centerTitle: true,
            elevation: 1,
          ),
          body: Column(
            children: [
              // Video Player
              player,

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
                child: _buildVideoList(studentProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoList(StudentProvider studentProvider) {
    return StreamBuilder<List<VideoModel>>(
      stream: studentProvider.getVideos(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
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
            final isSelected = _currentVideo != null && _currentVideo!.id == video.id;

            return VideoListItem(
              video: video,
              isSelected: isSelected,
              onTap: () => _changeVideo(video),
            );
          },
        );
      },
    );
  }
}