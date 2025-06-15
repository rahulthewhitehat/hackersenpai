import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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

class WindowsVideoPlaylistScreen extends StatefulWidget {
  final String courseId;
  final String chapterId;

  const WindowsVideoPlaylistScreen({
    super.key,
    required this.courseId,
    required this.chapterId,
  });

  @override
  _WindowsVideoPlaylistScreenState createState() => _WindowsVideoPlaylistScreenState();
}

class _WindowsVideoPlaylistScreenState extends State<WindowsVideoPlaylistScreen> {
  InAppWebViewController? _webViewController;
  VideoModel? _currentVideo;
  NoteModel? _currentNote;
  ChapterModel? _currentChapter;
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  bool _showNotes = false;
  bool _isWebViewLoading = false;
  double _videoProgress = 0.0;
  double _videoDuration = 0.0;
  double _playbackSpeed = 1.0;
  bool _isPlaying = true;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _webViewController?.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    try {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);

      final chaptersStream = studentProvider.getChapters();
      if (chaptersStream == null) {
        throw Exception('Chapters stream is null');
      }
      final chapters = await chaptersStream.first.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timed out fetching chapters'),
      );
      _currentChapter = chapters.firstWhere(
            (c) => c.id == widget.chapterId,
        orElse: () => throw Exception('Chapter not found'),
      );

      final videosStream = studentProvider.getVideos();
      if (videosStream == null) {
        throw Exception('Videos stream is null');
      }
      final videos = await videosStream.first.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timed out fetching videos'),
      );

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

        _isInitialized = true;
      } else {
        final notesStream = studentProvider.getNotes();
        if (notesStream == null) {
          throw Exception('Notes stream is null');
        }
        final notes = await notesStream.first.timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Timed out fetching notes'),
        );
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Failed to load content: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeVideo(VideoModel video) async {
    if (_currentVideo?.id == video.id && _webViewController != null) return;

    _progressTimer?.cancel();
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    studentProvider.selectVideo(video);

    if (mounted) {
      setState(() {
        _currentVideo = video;
        _currentNote = null;
        _isWebViewLoading = true;
        _webViewController = null;
        _videoProgress = 0.0;
        _videoDuration = 0.0;
        _playbackSpeed = 1.0;
        _isPlaying = true;
      });
    }

    try {
      final videoId = video.videoId;
      if (videoId.isEmpty) {
        throw Exception('Invalid YouTube video ID for video: ${video.name}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Failed to load video: ${e.toString()}';
          _isWebViewLoading = false;
        });
      }
    }
  }

  Future<double?> _getCurrentTime() async {
    if (_webViewController != null) {
      final result = await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video")?.currentTime || 0;',
      );
      return double.tryParse(result.toString());
    }
    return null;
  }

  Future<void> _setCurrentTime(double time) async {
    if (_webViewController != null) {
      await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video").currentTime = $time;',
      );
    }
  }

  Future<void> _togglePlayPause() async {
    if (_webViewController != null) {
      final isPaused = await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video")?.paused || false;',
      );
      if (isPaused == true) {
        await _webViewController!.evaluateJavascript(
          source: 'document.querySelector("video").play();',
        );
        if (mounted) {
          setState(() {
            _isPlaying = true;
          });
        }
      } else {
        await _webViewController!.evaluateJavascript(
          source: 'document.querySelector("video").pause();',
        );
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      }
    }
  }

  Future<void> _pauseVideo() async {
    if (_webViewController != null) {
      await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video")?.pause();',
      );
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  Future<void> _playVideo() async {
    if (_webViewController != null) {
      await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video")?.play();',
      );
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
    }
  }

  Future<void> _updateProgress() async {
    if (_webViewController != null && mounted) {
      final duration = await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video")?.duration || 0;',
      );
      final currentTime = await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video")?.currentTime || 0;',
      );
      final isPaused = await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video")?.paused || false;',
      );
      if (mounted) {
        setState(() {
          _videoDuration = double.tryParse(duration.toString()) ?? 0.0;
          _videoProgress = _videoDuration > 0
              ? (double.tryParse(currentTime.toString()) ?? 0.0) / _videoDuration
              : 0.0;
          _isPlaying = !(isPaused == true);
        });
      }
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _updateProgress();
    });
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    if (_webViewController != null) {
      await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video").playbackRate = $speed;',
      );
      if (mounted) {
        setState(() {
          _playbackSpeed = speed;
        });
      }
    }
  }

  Future<void> _seekTo(double progress) async {
    if (_webViewController != null && _videoDuration > 0) {
      final seekTime = progress * _videoDuration;
      await _setCurrentTime(seekTime);
      await _updateProgress();
    }
  }

  Future<void> _changeNote(NoteModel note) async {
    _progressTimer?.cancel();
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
          await Navigator.push(
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
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Failed to load note: ${e.toString()}';
        });
      }
    }
  }

  void _retryPlayback() {
    _progressTimer?.cancel();
    if (_currentVideo != null || _currentNote != null || _isError) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _isError = false;
          _errorMessage = '';
          _isWebViewLoading = false;
          _webViewController = null;
          _videoProgress = 0.0;
          _videoDuration = 0.0;
          _playbackSpeed = 1.0;
          _isPlaying = true;
        });
      }
      _initializeScreen();
    }
  }

  Widget _buildVideoPlayer() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final studentProvider = Provider.of<StudentProvider>(context);
    final watermarkText = "${studentProvider.student?.email ?? ''}\n${studentProvider.student?.studentId ?? ''}";

    return Stack(
      children: [
        Container(
          height: 300,
          color: Colors.black,
          child: _currentVideo != null
              ? InAppWebView(
            key: ValueKey(_currentVideo!.id),
            initialUrlRequest: URLRequest(
              url: WebUri(
                  'https://www.youtube-nocookie.com/embed/${_currentVideo!.videoId}?autoplay=1&origin=https://www.youtube.com&controls=0&rel=0&modestbranding=1&showinfo=0'),
              headers: {
                'Referer': 'https://www.youtube.com',
              },
            ),
            initialSettings: InAppWebViewSettings(
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              javaScriptEnabled: true,
              useHybridComposition: true,
              cacheEnabled: true,
              transparentBackground: true,
              supportZoom: false,
              disableContextMenu: true,
              iframeAllow: 'autoplay; fullscreen',
              iframeAllowFullscreen: true,
              userAgent:
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
              disableHorizontalScroll: true,
              disableVerticalScroll: true,
              allowContentAccess: false,
            ),
            onWebViewCreated: (controller) async {
              _webViewController = controller;
              await controller.evaluateJavascript(source: '''
                      document.querySelectorAll('.ytp-chrome-top, .ytp-chrome-bottom, .ytp-share-button, .ytp-embed-logo, .ytp-impression-link, .ytp-watermark').forEach(el => el.style.display = 'none');
                      document.querySelectorAll('a, button, .ytp-button').forEach(el => el.onclick = () => false);
                      document.body.style.userSelect = 'none';
                      document.body.oncontextmenu = () => false;
                      var style = document.createElement('style');
                      style.innerHTML = 'body, iframe { user-select: none; -webkit-user-select: none; pointer-events: auto; }';
                      document.querySelector("video").playbackRate = $_playbackSpeed;
                    ''');
              _startProgressTimer();
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url.toString();
              if (url.startsWith('https://www.youtube-nocookie.com/embed/${_currentVideo!.videoId}')) {
                return NavigationActionPolicy.ALLOW;
              }
              return NavigationActionPolicy.CANCEL;
            },
            onLoadStart: (controller, url) {
              if (mounted) {
                setState(() {
                  _isWebViewLoading = true;
                });
              }
            },
            onLoadStop: (controller, url) async {
              if (mounted) {
                setState(() {
                  _isWebViewLoading = false;
                });
              }
              await controller.evaluateJavascript(source: '''
                      document.querySelectorAll('.ytp-chrome-top, .ytp-chrome-bottom, .ytp-share-button, .ytp-embed-logo, .ytp-impression-link, .ytp-watermark').forEach(el => el.style.display = 'none');
                      document.querySelectorAll('a, button, .ytp-button').forEach(el => el.onclick = () => false);
                      document.body.style.userSelect = 'none';
                      document.body.oncontextmenu = () => false;
                      document.querySelector("video").playbackRate = $_playbackSpeed;
                    ''');
              _startProgressTimer();
            },
            onLoadError: (controller, url, code, message) {
              _progressTimer?.cancel();
              if (mounted) {
                setState(() {
                  _isError = true;
                  _errorMessage = 'Failed to load video: $message';
                  _isWebViewLoading = false;
                });
              }
            },
            onConsoleMessage: (controller, consoleMessage) {
              if (kDebugMode) {
                print('[InAppWebView] Console: ${consoleMessage.message}');
              }
            },
          )
              : Center(
            child: Text(
              'No video selected',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
            ),
          ),
        ),
        if (_isWebViewLoading)
          const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        Positioned.fill(
          child: FloatingWatermark(
            text: watermarkText,
            opacity: 0.2,
            constrainToPlayer: true,
          ),
        ),
        Positioned(
          bottom: 20,
          left: 8,
          right: 8,
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (details) {
                      final position = details.localPosition.dx;
                      final progress = position / constraints.maxWidth;
                      _seekTo(progress.clamp(0.0, 1.0));
                    },
                    onHorizontalDragUpdate: (details) {
                      final position = details.localPosition.dx;
                      final progress = position / constraints.maxWidth;
                      _seekTo(progress.clamp(0.0, 1.0));
                    },
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        LinearProgressIndicator(
                          value: _videoProgress,
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                        Positioned(
                          left: _videoProgress * constraints.maxWidth - 6,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white),
                        onPressed: () async {
                          final currentTime = await _getCurrentTime() ?? 0.0;
                          await _setCurrentTime((currentTime - 10).clamp(0.0, _videoDuration));
                          await _updateProgress();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white),
                        onPressed: () async {
                          final currentTime = await _getCurrentTime() ?? 0.0;
                          await _setCurrentTime((currentTime + 10).clamp(0.0, _videoDuration));
                          await _updateProgress();
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      DropdownButton<double>(
                        value: _playbackSpeed,
                        items: const [
                          DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                          DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                          DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                          DropdownMenuItem(value: 2.0, child: Text('2.0x')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _setPlaybackSpeed(value);
                          }
                        },
                        dropdownColor: Colors.black.withOpacity(0.8),
                        style: const TextStyle(color: Colors.white),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.white),
                        onPressed: () async {
                          if (_currentVideo != null) {
                            final currentTime = await _getCurrentTime() ?? 0.0;
                            await _pauseVideo();
                            _progressTimer?.cancel();
                            if (mounted) {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenVideoPlayer(
                                    video: _currentVideo!,
                                    watermarkText: watermarkText,
                                    initialTime: currentTime,
                                    initialSpeed: _playbackSpeed,
                                  ),
                                ),
                              );
                              if (result is Map && mounted) {
                                await _setCurrentTime(result['currentTime'] ?? 0.0);
                                await _setPlaybackSpeed(result['playbackSpeed'] ?? 1.0);
                                if (result['isPlaying'] == true) {
                                  await _playVideo();
                                } else {
                                  await _pauseVideo();
                                }
                                _startProgressTimer();
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = themeProvider.isDarkMode;

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
              fontWeight: FontWeight.w600,
              fontSize: 20,
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _currentChapter?.name ?? 'Content Player',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
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
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                if (_currentVideo != null) _buildVideoPlayer(),
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
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                              fontSize: 20,
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
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (mounted) {
                              setState(() {
                                _showNotes = false;
                              });
                            }
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
                                color: !_showNotes
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (mounted) {
                              setState(() {
                                _showNotes = true;
                              });
                            }
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
                                color: _showNotes
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
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
          ),
        ],
      ),
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final VideoModel video;
  final String watermarkText;
  final double initialTime;
  final double initialSpeed;

  const FullScreenVideoPlayer({
    super.key,
    required this.video,
    required this.watermarkText,
    this.initialTime = 0.0,
    this.initialSpeed = 1.0,
  });

  @override
  _FullScreenVideoPlayerState createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  InAppWebViewController? _webViewController;
  bool _isWebViewLoading = false;
  double _videoProgress = 0.0;
  double _videoDuration = 0.0;
  double _playbackSpeed = 1.0;
  bool _isPlaying = true;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _playbackSpeed = widget.initialSpeed;
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _webViewController?.dispose();
    super.dispose();
  }

  Future<double?> _getCurrentTime() async {
    if (_webViewController != null) {
      final result = await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video")?.currentTime || 0;',
      );
      return double.tryParse(result.toString());
    }
    return null;
  }

  Future<void> _setCurrentTime(double time) async {
    if (_webViewController != null) {
      await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video").currentTime = $time;',
      );
    }
  }

  Future<void> _togglePlayPause() async {
    if (_webViewController != null) {
      final isPaused = await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video")?.paused || false;',
      );
      if (isPaused == true) {
        await _webViewController!.evaluateJavascript(
          source: 'document.querySelector("video").play();',
        );
        if (mounted) {
          setState(() {
            _isPlaying = true;
          });
        }
      } else {
        await _webViewController!.evaluateJavascript(
          source: 'document.querySelector("video").pause();',
        );
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      }
    }
  }

  Future<void> _pauseVideo() async {
    if (_webViewController != null) {
      await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video")?.pause();',
      );
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  Future<void> _playVideo() async {
    if (_webViewController != null) {
      await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video")?.play();',
      );
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
    }
  }

  Future<void> _updateProgress() async {
    if (_webViewController != null && mounted) {
      final duration = await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video")?.duration || 0;',
      );
      final currentTime = await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video")?.currentTime || 0;',
      );
      final isPaused = await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video")?.paused || false;',
      );
      if (mounted) {
        setState(() {
          _videoDuration = double.tryParse(duration.toString()) ?? 0.0;
          _videoProgress = _videoDuration > 0
              ? (double.tryParse(currentTime.toString()) ?? 0.0) / _videoDuration
              : 0.0;
          _isPlaying = !(isPaused == true);
        });
      }
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _updateProgress();
    });
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    if (_webViewController != null) {
      await _webViewController!.evaluateJavascript(
        source: 'document.querySelector("video").playbackRate = $speed;',
      );
      if (mounted) {
        setState(() {
          _playbackSpeed = speed;
        });
      }
    }
  }

  Future<void> _seekTo(double progress) async {
    if (_webViewController != null && _videoDuration > 0) {
      final seekTime = progress * _videoDuration;
      await _setCurrentTime(seekTime);
      await _updateProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          InAppWebView(
            key: ValueKey(widget.video.id),
            initialUrlRequest: URLRequest(
              url: WebUri(
                  'https://www.youtube-nocookie.com/embed/${widget.video.videoId}?autoplay=1&origin=https://www.youtube.com&controls=0&rel=0&modestbranding=1&showinfo=0&start=${widget.initialTime.toInt()}'),
              headers: {
                'Referer': 'https://www.youtube.com',
              },
            ),
            initialSettings: InAppWebViewSettings(
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              javaScriptEnabled: true,
              useHybridComposition: true,
              cacheEnabled: true,
              transparentBackground: true,
              supportZoom: false,
              disableContextMenu: true,
              iframeAllow: 'autoplay; fullscreen',
              iframeAllowFullscreen: true,
              userAgent:
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
              disableHorizontalScroll: true,
              disableVerticalScroll: true,
              allowContentAccess: false,
            ),
            onWebViewCreated: (controller) async {
              _webViewController = controller;
              await controller.evaluateJavascript(source: '''
                document.querySelectorAll('.ytp-chrome-top, .ytp-chrome-bottom, .ytp-share-button, .ytp-embed-logo, .ytp-impression-link, .ytp-watermark').forEach(el => el.style.display = 'none');
                document.querySelectorAll('a, button, .ytp-button').forEach(el => el.onclick = () => false);
                document.body.style.userSelect = 'none';
                document.body.oncontextmenu = () => false;
                var style = document.createElement('style');
                style.innerHTML = 'body, iframe { user-select: none; -webkit-user-select: none; pointer-events: auto; }';
                document.querySelector("video").playbackRate = $_playbackSpeed;
              ''');
              await _setCurrentTime(widget.initialTime);
              await _playVideo();
              _startProgressTimer();
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url.toString();
              if (url.startsWith('https://www.youtube-nocookie.com/embed/${widget.video.videoId}')) {
                return NavigationActionPolicy.ALLOW;
              }
              return NavigationActionPolicy.CANCEL;
            },
            onLoadStart: (controller, url) {
              if (mounted) {
                setState(() {
                  _isWebViewLoading = true;
                });
              }
            },
            onLoadStop: (controller, url) async {
              if (mounted) {
                setState(() {
                  _isWebViewLoading = false;
                });
              }
              await controller.evaluateJavascript(source: '''
                document.querySelectorAll('.ytp-chrome-top, .ytp-chrome-bottom, .ytp-share-button, .ytp-embed-logo, .ytp-impression-link, .ytp-watermark').forEach(el => el.style.display = 'none');
                document.querySelectorAll('a, button, .ytp-button').forEach(el => el.onclick = () => false);
                document.body.style.userSelect = 'none';
                document.body.oncontextmenu = () => false;
                document.querySelector("video").playbackRate = $_playbackSpeed;
              ''');
              await _setCurrentTime(widget.initialTime);
              await _playVideo();
              _startProgressTimer();
            },
            onLoadError: (controller, url, code, message) {
              _progressTimer?.cancel();
              if (mounted) {
                Navigator.pop(context);
              }
            },
          ),
          if (_isWebViewLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          Positioned.fill(
            child: FloatingWatermark(
              text: widget.watermarkText,
              opacity: 0.2,
              constrainToPlayer: false,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
              onPressed: () async {
                _progressTimer?.cancel();
                await _pauseVideo();
                final currentTime = await _getCurrentTime() ?? 0.0;
                Navigator.pop(context, {
                  'currentTime': currentTime,
                  'playbackSpeed': _playbackSpeed,
                  'isPlaying': _isPlaying,
                });
              },
            ),
          ),
          Positioned(
            bottom: 20,
            left: 8,
            right: 8,
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapDown: (details) {
                        final position = details.localPosition.dx;
                        final progress = position / constraints.maxWidth;
                        _seekTo(progress.clamp(0.0, 1.0));
                      },
                      onHorizontalDragUpdate: (details) {
                        final position = details.localPosition.dx;
                        final progress = position / constraints.maxWidth;
                        _seekTo(progress.clamp(0.0, 1.0));
                      },
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          LinearProgressIndicator(
                            value: _videoProgress,
                            backgroundColor: Colors.grey.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          ),
                          Positioned(
                            left: _videoProgress * constraints.maxWidth - 6,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                        IconButton(
                          icon: const Icon(Icons.replay_10, color: Colors.white),
                          onPressed: () async {
                            final currentTime = await _getCurrentTime() ?? 0.0;
                            await _setCurrentTime((currentTime - 10).clamp(0.0, _videoDuration));
                            await _updateProgress();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.forward_10, color: Colors.white),
                          onPressed: () async {
                            final currentTime = await _getCurrentTime() ?? 0.0;
                            await _setCurrentTime((currentTime + 10).clamp(0.0, _videoDuration));
                            await _updateProgress();
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        DropdownButton<double>(
                          value: _playbackSpeed,
                          items: const [
                            DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                            DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                            DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                            DropdownMenuItem(value: 2.0, child: Text('2.0x')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _setPlaybackSpeed(value);
                            }
                          },
                          dropdownColor: Colors.black.withOpacity(0.8),
                          style: const TextStyle(color: Colors.white),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                          onPressed: () async {
                            _progressTimer?.cancel();
                            await _pauseVideo();
                            final currentTime = await _getCurrentTime() ?? 0.0;
                            Navigator.pop(context, {
                              'currentTime': currentTime,
                              'playbackSpeed': _playbackSpeed,
                              'isPlaying': _isPlaying,
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}