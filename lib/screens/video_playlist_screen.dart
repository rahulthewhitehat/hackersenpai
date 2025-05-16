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
      final isActuallyFullScreen = _controller.value.isFullScreen || orientation == Orientation.landscape;
      if (isActuallyFullScreen != _isFullScreen) {
        setState(() {
          _isFullScreen = isActuallyFullScreen;
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
          VideoModel? chapterVideo = videos.firstWhere((v) => v.chapterId == widget.chapterId, orElse: () => videos.first);
          _currentVideo = studentProvider.selectedVideo ?? chapterVideo;


          if (_currentVideo == null || (_currentVideo!.chapterId != widget.chapterId && videos.any((v) => v.chapterId == widget.chapterId))) {
            _currentVideo = videos.firstWhere((v) => v.chapterId == widget.chapterId, orElse: () => videos.first);
          }
          studentProvider.selectVideo(_currentVideo!);


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

          _controller.addListener(_onControllerUpdate);
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
    if (!_isInitialized) return;
    final isFullScreenFromController = _controller.value.isFullScreen;
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
    if (_currentVideo?.id == video.id && _controller.metadata.videoId == video.videoId) return;


    final studentProvider = Provider.of<StudentProvider>(
        context, listen: false);
    studentProvider.selectVideo(video);

    setState(() {
      _currentVideo = video;
    });

    try {
      _controller.load(video.videoId);
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

  // ONLY THIS METHOD IS MODIFIED SIGNIFICANTLY
  YoutubePlayer _buildVideoPlayer() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const iconColor = Colors.white;

    return YoutubePlayer(
      controller: _controller,
      showVideoProgressIndicator: true,
      progressIndicatorColor: colorScheme.primary,
      bottomActions: [
        CurrentPosition(controller: _controller),
        IconButton(
          icon: const Icon(Icons.replay_10, color: iconColor, size: 28.0),
          onPressed: !_isInitialized
              ? null
              : () {
            final currentPosition = _controller.value.position;
            var newPosition = currentPosition - const Duration(seconds: 10);
            if (newPosition < Duration.zero) {
              newPosition = Duration.zero;
            }
            _controller.seekTo(newPosition);
          },
        ),
        Expanded(
          child: ProgressBar(
            controller: _controller,
            colors: ProgressBarColors(
              playedColor: colorScheme.primary,
              handleColor: colorScheme.primary,
              bufferedColor: colorScheme.primaryContainer.withOpacity(0.7),
              backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.forward_10, color: iconColor, size: 28.0),
          onPressed: !_isInitialized
              ? null
              : () {
            final currentPosition = _controller.value.position;
            final videoDuration = _controller.metadata.duration;
            var newPosition = currentPosition + const Duration(seconds: 10);
            if (videoDuration > Duration.zero && newPosition > videoDuration) {
              newPosition = videoDuration;
            }
            _controller.seekTo(newPosition);
          },
        ),
        RemainingDuration(controller: _controller),
        PlaybackSpeedButton( // ADDED PLAYBACK SPEED BUTTON
          controller: _controller,
          //iconColor: iconColor, // Optional: ensure icon color consistency
        ),
        FullScreenButton(controller: _controller),
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
    final student = studentProvider.student;
    final isLandscape = MediaQuery
        .of(context)
        .orientation == Orientation.landscape;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

    if (_isError || !_isInitialized || _currentVideo == null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            _currentChapter?.name ?? (_isError ? 'Error' : 'Video Player'),
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

        if (_isFullScreen) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: playerWithWatermark,
            ),
          );
        }

        if (isLandscape) {
          return Scaffold(
            backgroundColor: Colors.black,
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
                          color: theme.canvasColor,
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
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
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
                        backgroundColor: Colors.black.withOpacity(0.6),
                        onPressed: _togglePlaylistVisibility,
                        child: Icon(
                          _showPlaylistInLandscape ? Icons.arrow_forward_ios : Icons.playlist_play,
                          color: Colors.white,
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
              Container(
                margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
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
                    Icon(Icons.playlist_play, color: colorScheme.primary,
                        size: 26),
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
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          );
        }
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(snapshot.error.toString(), style: theme.textTheme.bodySmall, textAlign: TextAlign.center,),
                ),
              ],
            ),
          );
        }

        final allVideos = snapshot.data;
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


        return ListView.separated(
          itemCount: videos.length,
          padding: const EdgeInsets.only(bottom: 32, top: 12),
          separatorBuilder: (context, index) => Divider(indent: 16, endIndent: 16, height:1, color: colorScheme.outlineVariant.withOpacity(0.5)),
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