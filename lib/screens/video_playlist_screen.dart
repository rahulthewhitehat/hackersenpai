import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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
  bool _isFullScreen = false;
  OverlayEntry? _watermarkOverlay;
  final GlobalKey _videoPlayerKey = GlobalKey();

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
    _removeWatermarkOverlay();
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
    if (_isInitialized && _currentVideo != null) {
      final orientation = MediaQuery
          .of(context)
          .orientation;
      final isFullScreen = orientation == Orientation.landscape ||
          _controller.value.isFullScreen;
      if (isFullScreen != _isFullScreen) {
        setState(() {
          _isFullScreen = isFullScreen;
        });
        _updateWatermarkOverlay();
      }
    }
  }

  void _updateWatermarkOverlay() {
    final studentProvider = Provider.of<StudentProvider>(
        context, listen: false);
    final student = studentProvider.student;
    final watermarkText = "${student?.email ?? ''}\n${student?.studentId ??
        ''}";

    if (_isFullScreen) {
      _removeWatermarkOverlay();
      _watermarkOverlay = OverlayEntry(
        builder: (context) =>
            Positioned.fill(
              child: FloatingWatermark(
                text: watermarkText,
                opacity: 0.2,
                constrainToPlayer: false,
              ),
            ),
      );
      Overlay.of(context).insert(_watermarkOverlay!);
    } else {
      _removeWatermarkOverlay();
    }
  }

  void _removeWatermarkOverlay() {
    _watermarkOverlay?.remove();
    _watermarkOverlay = null;
  }

  Future<void> _initializeScreen() async {
    try {
      final studentProvider = Provider.of<StudentProvider>(
          context, listen: false);

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

          // Add listener to detect fullscreen changes
          _controller.addListener(_onControllerUpdate);

          _isInitialized = true;
        } else {
          setState(() {
            _isError = true;
            _errorMessage = 'No videos available in this chapter';
          });
        }
      }
    } catch (e) {
      //print('Error initializing screen: $e');
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

  void _onControllerUpdate() {
    // Update fullscreen state when YouTube player state changes
    final isFullScreenFromController = _controller.value.isFullScreen;
    if (isFullScreenFromController != _isFullScreen) {
      setState(() {
        _isFullScreen = isFullScreenFromController;
      });
      _updateWatermarkOverlay();
    }
  }

  void _togglePlaylistVisibility() {
    setState(() {
      _showPlaylistInLandscape = !_showPlaylistInLandscape;
      _playlistWidth = _showPlaylistInLandscape ? 300.0 : 0.0;
    });
  }

  Future<void> _changeVideo(VideoModel video) async {
    if (_currentVideo?.id == video.id) return;

    final studentProvider = Provider.of<StudentProvider>(
        context, listen: false);
    studentProvider.selectVideo(video);

    setState(() {
      _isLoading = true;
      _currentVideo = video;
    });

    try {
      _controller.load(video.videoId);
      _controller.play();
      _updateWatermarkOverlay(); // Update watermark when video changes
    } catch (e) {
      //print('Error changing video: $e');
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

  Widget _buildVideoPlayerWithWatermark(Widget player, String watermarkText) {
    return Stack(
      key: _videoPlayerKey,
      children: [
        // The YouTube player
        player,
        // Watermark overlay constrained to player area (only in portrait)
        if (!_isFullScreen)
          Positioned.fill(
            child: FloatingWatermark(
              text: watermarkText,
              opacity: 0.2,
              constrainToPlayer: true,
            ),
          ),
      ],
    );
  }

  YoutubePlayer _buildVideoPlayer() {
    return YoutubePlayer(
      controller: _controller,
      showVideoProgressIndicator: true,
      progressIndicatorColor: Theme
          .of(context)
          .colorScheme
          .primary,
      progressColors: ProgressBarColors(
        playedColor: Theme
            .of(context)
            .colorScheme
            .primary,
        handleColor: Theme
            .of(context)
            .colorScheme
            .primary,
        bufferedColor: Theme
            .of(context)
            .colorScheme
            .primaryContainer,
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .surfaceContainerHighest,
      ),
      onReady: () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final student = studentProvider.student;
    final isLandscape = MediaQuery
        .of(context)
        .orientation == Orientation.landscape;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Prepare watermark text
    final watermarkText = "${student?.email ?? ''}\n${student?.studentId ??
        ''}";

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading content...',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isError) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            _currentChapter?.name ?? 'Error',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.cyanAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 72,
                  color: colorScheme.error.withOpacity(0.8),
                ),
                const SizedBox(height: 24),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _retryPlayback,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: _buildVideoPlayer(),
      builder: (context, player) {
        Widget playerWithWatermark = _buildVideoPlayerWithWatermark(
            player, watermarkText);

        if (isLandscape) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // Player with watermark
                Positioned.fill(child: playerWithWatermark),

                // Playlist toggle button
                if (_isFullScreen)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.black.withOpacity(0.8),
                      elevation: 4,
                      onPressed: _togglePlaylistVisibility,
                      child: Icon(
                        _showPlaylistInLandscape ? Icons.close : Icons
                            .playlist_play,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                // Sliding playlist
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  right: _playlistWidth - 300,
                  top: 0,
                  bottom: 0,
                  width: 300,
                  child: Material(
                    elevation: 12,
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(-4, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Chapter name header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primaryContainer
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _currentChapter?.name ?? 'Videos',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.close, color: Colors.white,
                                      size: 24),
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
                ),
              ],
            ),
          );
        }

        // Portrait mode
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: Text(
              _currentChapter?.name ?? 'Video Player',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.cyanAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Video Player with watermark
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: playerWithWatermark,
                  ),
                ),
              ),

              // Video info
              if (_currentVideo != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _currentVideo!.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            fontSize: 20,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_currentVideo!.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _currentVideo!.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Playlist header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.surfaceContainerHighest,
                      width: 1.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.playlist_play, color: colorScheme.primary,
                        size: 26),
                    const SizedBox(width: 8),
                    Text(
                      'Playlist',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _currentChapter?.name ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<List<VideoModel>>(
      stream: studentProvider.getVideos(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 56,
                  color: colorScheme.error.withOpacity(0.8),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading videos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
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
                  size: 56,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No videos available',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: videos.length,
          padding: const EdgeInsets.only(bottom: 32, top: 12),
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final video = videos[index];
            final isSelected = _currentVideo != null &&
                _currentVideo!.id == video.id;

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