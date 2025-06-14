import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/chapter_model.dart';
import '../models/video_model.dart';
import '../models/note_model.dart';
import '../providers/student_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/video_list_item.dart';
import '../widgets/note_list_item.dart';
import '../widgets/floating_watermark.dart';
import './pdf_viewer_screen.dart';

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
  NoteModel? _currentNote;
  ChapterModel? _currentChapter;
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  bool _isFullScreen = false;
  bool _showNotes = false;
  bool _showPlaylistInLandscape = false;
  double _playlistWidth = 0.0;
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
              hideThumbnail: true,
            ),
          );

          _controller!.addListener(_onControllerUpdate);
          _isInitialized = true;
        } else {
          final notesStream = studentProvider.getNotes();
          if (notesStream != null) {
            final notes = await notesStream.first;
            if (notes.isNotEmpty) {
              _currentNote = studentProvider.selectedNote ?? notes.first;
              studentProvider.selectNote(_currentNote!);
              _isInitialized = true;
            } else {
              setState(() {
                _isError = true;
                _errorMessage = 'No videos or notes available in this chapter';
              });
            }
          } else {
            setState(() {
              _isError = true;
              _errorMessage = 'No content stream available';
            });
          }
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
      _currentNote = null;
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

  Future<void> _changeNote(NoteModel note) async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    studentProvider.selectNote(note);

    try {
      final response = await http.get(Uri.parse(note.link));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/${note.id}.pdf');
        await file.writeAsBytes(response.bodyBytes);
        final student = studentProvider.student;
        final watermarkText = "${student?.email ?? ''}\n${student?.studentId ?? ''}";
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerScreen(
                pdfPath: file.path,
                noteName: note.name,
                noteDescription: note.description,
                watermarkText: watermarkText,
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = 'Failed to load note: ${e.toString()}';
      });
    }
  }

  void _retryPlayback() {
    if (_currentVideo != null || _currentNote != null || _isError) {
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
          icon: const Icon(Icons.replay_10, color: Colors.white, size: 28.0),
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
            colors: const ProgressBarColors(
              playedColor: Colors.blue,
              handleColor: Colors.blue,
              bufferedColor: Colors.blueGrey,
              backgroundColor: Colors.grey,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.forward_10, color: Colors.white, size: 28.0),
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

            final progressData = progressSnapshot.data ?? [];
            final completedVideoIds = progressData
                .where((progress) => progress['completed'] == true)
                .map((progress) => progress['videoId'] as String)
                .toSet();

            final updatedVideos = videos.map((video) {
              return VideoModel(
                id: video.id,
                name: video.name,
                description: video.description,
                link: video.link,
                courseId: video.courseId,
                chapterId: video.chapterId,
                order: video.order,
                completed: completedVideoIds.contains(video.id),
                videoId: video.videoId,
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

  Widget _buildNoteList(StudentProvider studentProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<List<NoteModel>>(
      stream: studentProvider.getNotes(),
      builder: (context, noteSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: studentProvider.getNoteProgress(),
          builder: (context, progressSnapshot) {
            if (noteSnapshot.connectionState == ConnectionState.waiting && !noteSnapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              );
            }
            if (noteSnapshot.hasError) {
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
                      'Error loading notes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        noteSnapshot.error.toString(),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            final allNotes = noteSnapshot.data;
            if (allNotes == null || allNotes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 56,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notes available',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }
            final notes = allNotes.where((note) => note.chapterId == widget.chapterId).toList();

            if (notes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 56,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notes in this chapter',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            final progressData = progressSnapshot.data ?? [];
            final completedNoteIds = progressData
                .where((progress) => progress['completed'] == true)
                .map((progress) => progress['noteId'] as String)
                .toSet();

            final updatedNotes = notes.map((note) {
              return NoteModel(
                id: note.id,
                name: note.name,
                description: note.description,
                link: note.link,
                courseId: note.courseId,
                chapterId: note.chapterId,
                order: note.order,
                completed: completedNoteIds.contains(note.id),
              );
            }).toList();

            return ListView.separated(
              itemCount: updatedNotes.length,
              padding: const EdgeInsets.only(bottom: 32, top: 12),
              separatorBuilder: (context, index) => Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),
              itemBuilder: (context, index) {
                final note = updatedNotes[index];
                final isSelected = _currentNote != null && _currentNote!.id == note.id;

                return NoteListItem(
                  note: note,
                  isSelected: isSelected,
                  onTap: () => _changeNote(note),
                );
              },
            );
          },
        );
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

    if (_isError || !_isInitialized || (_currentVideo == null && _currentNote == null)) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            _currentChapter?.name ?? (_isError ? 'Error' : 'Content Player'),
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
                  _errorMessage.isNotEmpty ? _errorMessage : 'Could not load content.',
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
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                                      _currentChapter?.name ?? (_showNotes ? 'Notes' : 'Videos'),
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: colorScheme.onPrimary,
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
                            Expanded(child: _showNotes ? _buildNoteList(studentProvider) : _buildVideoList(studentProvider)),
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
              _currentChapter?.name ?? 'Content Player',
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
              if (_currentVideo != null)
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
              if (_currentVideo != null || _currentNote != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _currentVideo?.name ?? _currentNote?.name ?? '',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            fontSize: 20,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if ((_currentVideo?.description ?? _currentNote?.description ?? '').isNotEmpty)
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                _currentVideo?.description ?? _currentNote?.description ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              StreamBuilder<Map<String, int>>(
                stream: studentProvider.getChapterProgress(widget.chapterId).asStream(),
                builder: (context, snapshot) {
                  int totalItems = 0;
                  int completedItems = 0;
                  double completionPercentage = 0.0;

                  if (snapshot.hasData) {
                    totalItems = snapshot.data!['totalItems'] ?? 0;
                    completedItems = snapshot.data!['completedItems'] ?? 0;
                    completionPercentage = totalItems > 0 ? (completedItems / totalItems) * 100 : 0.0;
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
                          'Progress: $completedItems/$totalItems items',
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showNotes = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: !_showNotes ? colorScheme.primary : colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Videos',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: !_showNotes ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showNotes = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: _showNotes ? colorScheme.primary : colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Notes',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _showNotes ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                    Icon(
                      _showNotes ? Icons.description : Icons.playlist_play,
                      color: colorScheme.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _showNotes ? 'Notes' : 'Playlist',
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
                child: _showNotes ? _buildNoteList(studentProvider) : _buildVideoList(studentProvider),
              ),
            ],
          ),
        );
      },
    );
  }
}