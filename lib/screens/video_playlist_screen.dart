import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import '../models/chapter_model.dart';
import '../models/video_model.dart';
import '../providers/student_provider.dart';
import '../providers/theme_provider.dart';
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
  YoutubePlayerController? _controller;
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
    if (_isInitialized && _controller != null) {
      _controller!.dispose();
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
      final orientation = MediaQuery.of(context).orientation;
      final isActuallyFullScreen = _controller?.value.isFullScreen ?? false || orientation == Orientation.landscape;
      if (isActuallyFullScreen != _isFullScreen) {
        setState(() {
          _isFullScreen = isActuallyFullScreen;
        });
        _updateWatermarkOverlay();
      }
    }
  }

  void _updateWatermarkOverlay() {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    final student = studentProvider.student;
    final watermarkText = "${student?.email ?? ''}\n${student?.studentId ?? ''}";

    if (_isFullScreen) {
      _removeWatermarkOverlay();
      _watermarkOverlay = OverlayEntry(
        builder: (context) => Positioned.fill(
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
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);

      final chaptersStream = studentProvider.getChapters();
      if (chaptersStream != null) {
        final chapters = await chaptersStream.first;
        _currentChapter = chapters.firstWhere(
              (c) => c.id == widget.chapterId,
          orElse: () => throw Exception('Chapter not found'),
        );
      }

      final videosStream = studentProvider.getVideos();
      if (videosStream != null) {
        final videos = await videosStream.first;
        if (videos.isNotEmpty) {
          VideoModel? chapterVideo = videos.firstWhere(
                (v) => v.chapterId == widget.chapterId,
            orElse: () => videos.first,
          );
          _currentVideo = studentProvider.selectedVideo ?? chapterVideo;

          if (_currentVideo == null ||
              (_currentVideo!.chapterId != widget.chapterId && videos.any((v) => v.chapterId == widget.chapterId))) {
            _currentVideo = videos.firstWhere(
                  (v) => v.chapterId == widget.chapterId,
              orElse: () => videos.first,
            );
          }
          studentProvider.selectVideo(_currentVideo!);

          // Validate videoId
          final videoId = _currentVideo!.videoId;
          if (videoId.isEmpty) {
            throw Exception('Invalid YouTube video ID for video: ${_currentVideo!.name}');
          }

          _controller = YoutubePlayerController(
            initialVideoId: videoId,
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
              // MODIFICATION: Hide thumbnail on pause and reduce branding.
              // This prevents the video thumbnail from showing when paused.
              hideThumbnail: true,
              // This reduces the YouTube logo in the control bar.

            ),
          );

          _controller!.addListener(_onControllerUpdate);
          _isInitialized = true;
        } else {
          setState(() {
            _isError = true;
            _errorMessage = 'No videos available in this chapter';
          });
        }
      } else {
        setState(() {
          _isError = true;
          _errorMessage = 'No videos stream available';
        });
      }
    } catch (e) {
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
    if (!_isInitialized || _controller == null) return;
    final isFullScreenFromController = _controller!.value.isFullScreen;
    if (isFullScreenFromController != _isFullScreen) {
      setState(() {
        _isFullScreen = isFullScreenFromController;
      });
      _updateWatermarkOverlay();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _togglePlaylistVisibility() {
    setState(() {
      _showPlaylistInLandscape = !_showPlaylistInLandscape;
      _playlistWidth = _showPlaylistInLandscape ? 300.0 : 0.0;
    });
  }

  Future<void> _changeVideo(VideoModel video) async {
    if (_currentVideo?.id == video.id && _controller?.metadata.videoId == video.videoId) return;

    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    studentProvider.selectVideo(video);

    setState(() {
      _currentVideo = video;
    });

    try {
      final videoId = video.videoId;
      if (videoId.isEmpty) {
        throw Exception('Invalid YouTube video ID for video: ${video.name}');
      }
      _controller?.load(videoId);
      _updateWatermarkOverlay();
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = 'Failed to load video: ${e.toString()}';
      });
    }
  }

  void _retryPlayback() {
    if (_currentVideo != null || _isError) {
      setState(() {
        _isLoading = true;
        _isError = false;
        _errorMessage = '';
      });
      _initializeScreen();
    }
  }

  Widget _buildVideoPlayerWithWatermark(Widget player, String watermarkText) {
    return Stack(
      key: _videoPlayerKey,
      children: [
        player,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return YoutubePlayer(
      controller: _controller!,
      showVideoProgressIndicator: true,
      progressIndicatorColor: colorScheme.primary,
      bottomActions: [
        CurrentPosition(controller: _controller!),
        IconButton(
          icon: Icon(Icons.replay_10, color: Colors.white, size: 28.0),
          onPressed: !_isInitialized
              ? null
              : () {
            final currentPosition = _controller!.value.position;
            var newPosition = currentPosition - const Duration(seconds: 10);
            if (newPosition < Duration.zero) {
              newPosition = Duration.zero;
            }
            _controller!.seekTo(newPosition);
          },
        ),
        Expanded(
          child: ProgressBar(
            controller: _controller!,
            colors: ProgressBarColors(
              playedColor: colorScheme.primary,
              handleColor: colorScheme.primary,
              bufferedColor: colorScheme.primaryContainer.withOpacity(0.7),
              backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.forward_10, color: Colors.white, size: 28.0),
          onPressed: !_isInitialized
              ? null
              : () {
            final currentPosition = _controller!.value.position;
            final videoDuration = _controller!.metadata.duration;
            var newPosition = currentPosition + const Duration(seconds: 10);
            if (videoDuration > Duration.zero && newPosition > videoDuration) {
              newPosition = videoDuration;
            }
            _controller!.seekTo(newPosition);
          },
        ),
        RemainingDuration(controller: _controller!),
        PlaybackSpeedButton(
          controller: _controller!,
        ),
        FullScreenButton(controller: _controller!),
      ],
      onReady: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final student = studentProvider.student;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = themeProvider.isDarkMode;

    final watermarkText = "${student?.email ?? ''}\n${student?.studentId ?? ''}";

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
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

    if (_isError || !_isInitialized || _currentVideo == null || _controller == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            _currentChapter?.name ?? (_isError ? 'Error' : 'Video Player'),
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
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
                  _errorMessage.isNotEmpty ? _errorMessage : "Could not load video content.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _retryPlayback,
                  icon: Icon(Icons.refresh, size: 20, color: colorScheme.onPrimary),
                  label: Text('Retry', style: TextStyle(color: colorScheme.onPrimary)),
                  style: theme.elevatedButtonTheme.style?.copyWith(
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
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
        Widget playerWithWatermark = _buildVideoPlayerWithWatermark(player, watermarkText);

        if (_isFullScreen) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: Center(
              child: playerWithWatermark,
            ),
          );
        }

        if (isLandscape) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: Row(
              children: [
                Expanded(
                  flex: _showPlaylistInLandscape ? 2 : 3,
                  child: playerWithWatermark,
                ),
                if (_showPlaylistInLandscape)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _playlistWidth,
                    curve: Curves.easeInOut,
                    child: Material(
                      elevation: 12,
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.onSurface.withOpacity(isDarkMode ? 0.1 : 0.15),
                              blurRadius: 12,
                              offset: const Offset(-4, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [colorScheme.primary, colorScheme.secondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _currentChapter?.name ?? 'Videos',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, color: colorScheme.onPrimary, size: 24),
                                    onPressed: _togglePlaylistVisibility,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: _buildVideoList(studentProvider)),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (!_isFullScreen)
                  Positioned(
                    top: 10,
                    right: _showPlaylistInLandscape ? _playlistWidth + 5 : 5,
                    child: Material(
                      color: Colors.transparent,
                      child: FloatingActionButton(
                        mini: true,
                        elevation: 2,
                        backgroundColor: colorScheme.surface.withOpacity(0.6),
                        onPressed: _togglePlaylistVisibility,
                        child: Icon(
                          _showPlaylistInLandscape ? Icons.arrow_forward_ios : Icons.playlist_play,
                          color: colorScheme.onSurface,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              _currentChapter?.name ?? 'Video Player',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.secondary],
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
              Container(
                margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.onSurface.withOpacity(isDarkMode ? 0.05 : 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: playerWithWatermark,
                ),
              ),

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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              StreamBuilder<Map<String, int>>(
                stream: studentProvider.getChapterProgress(widget.chapterId).asStream(),
                builder: (context, snapshot) {
                  int totalVideos = 0;
                  int completedVideos = 0;
                  double completionPercentage = 0.0;

                  if (snapshot.hasData) {
                    totalVideos = snapshot.data!['totalVideos'] ?? 0;
                    completedVideos = snapshot.data!['completedVideos'] ?? 0;
                    completionPercentage = totalVideos > 0 ? (completedVideos / totalVideos) * 100 : 0.0;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.onSurface.withOpacity(isDarkMode ? 0.05 : 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress: $completedVideos/$totalVideos videos',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${completionPercentage.toStringAsFixed(0)}% Complete',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
                    top: BorderSide(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.playlist_play, color: colorScheme.primary, size: 26),
                    const SizedBox(width: 10),
                    Text(
                      'Playlist',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        _currentChapter?.name ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

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
      builder: (context, videoSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: studentProvider.getVideoProgress(),
          builder: (context, progressSnapshot) {
            if (videoSnapshot.connectionState == ConnectionState.waiting && !videoSnapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              );
            }
            if (videoSnapshot.hasError) {
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
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        videoSnapshot.error.toString(),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            final allVideos = videoSnapshot.data;
            if (allVideos == null || allVideos.isEmpty) {
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
            final videos = allVideos.where((video) => video.chapterId == widget.chapterId).toList();

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
                      'No videos in this chapter',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Map video progress
            final progressData = progressSnapshot.data ?? [];
            final completedVideoIds = progressData
                .where((progress) => progress['completed'] == true)
                .map((progress) => progress['videoId'] as String)
                .toSet();

            // Update videos with completion status
            final updatedVideos = videos.map((video) {
              return VideoModel(
                id: video.id,
                name: video.name,
                description: video.description,
                link: video.link,
                courseId: video.courseId,
                chapterId: video.chapterId,
                order: video.order,
                completed: completedVideoIds.contains(video.id), videoId: video.videoId,
              );
            }).toList();

            return ListView.separated(
              itemCount: updatedVideos.length,
              padding: const EdgeInsets.only(bottom: 32, top: 12),
              separatorBuilder: (context, index) => Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
              itemBuilder: (context, index) {
                final video = updatedVideos[index];
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
      },
    );
  }
}
