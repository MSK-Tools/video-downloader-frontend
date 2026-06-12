import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:yt_downloader/core/theme/theme.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class PlayerScreen extends StatefulWidget {
  final String videoTitle;
  final String videoUrl;
  final bool isAudioOnly;
  final String thumbnailUrl;

  const PlayerScreen({
    super.key,
    required this.videoTitle,
    required this.videoUrl,
    required this.isAudioOnly,
    this.thumbnailUrl = '',
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // Video Player states
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // Audio Player states
  AudioPlayer? _audioPlayer;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  bool _isAudioPlaying = false;

  // Shared parameters
  bool _isPlaying = false;
  double _volume = 1.0;
  bool _isMiniPlayer = false;
  // New player features
  double _playbackSpeed = 1.0;
  bool _controlsLocked = false;
  bool _isFullscreen = false;
  int _rotationTurns = 0; // 0..3 quarter turns

  @override
  void initState() {
    super.initState();
    if (widget.isAudioOnly) {
      _initAudioPlayer();
    } else {
      _initVideoPlayer();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  // --- Video Controller Setup ---
  void _initVideoPlayer() {
    // Note: widget.videoUrl could be a local file path if yt-dlp was run locally,
    // or a remote media server URL from Django.
    final uri = Uri.parse(widget.videoUrl);
    _videoController = VideoPlayerController.networkUrl(uri)
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
          _videoController!.play();
          _isPlaying = true;
          _videoController!.setVolume(_volume);
        });
      });

    _videoController!.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    // Ensure initial playback speed
    _videoController!.setPlaybackSpeed(_playbackSpeed);
  }

  // --- Audio Player Setup ---
  void _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    
    // Listen to changes
    _audioPlayer!.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _audioDuration = dur);
    });
    
    _audioPlayer!.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _audioPosition = pos);
    });
    
    _audioPlayer!.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = state == PlayerState.playing;
          _isPlaying = _isAudioPlaying;
        });
      }
    });

    try {
      await _audioPlayer!.play(UrlSource(widget.videoUrl));
    } catch (_) {}
  }

  // --- Player Controls ---
  void _togglePlayPause() {
    if (widget.isAudioOnly) {
      if (_isPlaying) {
        _audioPlayer!.pause();
      } else {
        _audioPlayer!.resume();
      }
    } else {
      if (_videoController != null && _isVideoInitialized) {
        if (_isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
        setState(() {
          _isPlaying = !_isPlaying;
        });
      }
    }
  }

  void _seekRelative(int seconds) {
    if (widget.isAudioOnly) {
      final newPos = _audioPosition + Duration(seconds: seconds);
      _audioPlayer!.seek(newPos);
    } else {
      if (_videoController != null && _isVideoInitialized) {
        final newPos = _videoController!.value.position + Duration(seconds: seconds);
        _videoController!.seekTo(newPos);
      }
    }
  }

  void _changeVolume(double val) {
    setState(() {
      _volume = val;
    });
    if (widget.isAudioOnly) {
      _audioPlayer?.setVolume(val);
    } else {
      _videoController?.setVolume(val);
    }
  }

  void _setPlaybackSpeed(double speed) {
    setState(() => _playbackSpeed = speed);
    try {
      if (widget.isAudioOnly) {
        try {
          _audioPlayer?.setPlaybackRate(speed);
        } catch (_) {}
      } else {
        _videoController?.setPlaybackSpeed(speed);
      }
    } catch (_) {}
  }

  void _toggleControlsLock() {
    setState(() => _controlsLocked = !_controlsLocked);
  }

  Future<void> _toggleFullscreen() async {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _rotateVideo() {
    setState(() {
      _rotationTurns = (_rotationTurns + 1) % 4;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, "0")}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isMiniPlayer) {
      return _buildMiniPlayerLayout();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.isAudioOnly ? 'Audio Player' : 'Video Player',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _isMiniPlayer = true;
              });
            },
            tooltip: 'Mini-Player mode',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: widget.isAudioOnly ? _buildAudioVisualizer() : _buildVideoCanvas(),
              ),
            ),
            _buildPlayerControls(),
          ],
        ),
      ),
    );
  }

  // --- Video Render Area ---
  Widget _buildVideoCanvas() {
    if (!_isVideoInitialized) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: MskColors.secondary),
          SizedBox(height: 16),
          Text('Loading video stream...', style: TextStyle(color: Colors.white)),
        ],
      );
    }

    final videoWidget = AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_videoController!),
          VideoProgressIndicator(
            _videoController!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: MskColors.secondary,
              bufferedColor: Colors.white30,
              backgroundColor: Colors.white10,
            ),
          ),
        ],
      ),
    );

    // Apply rotation if needed
    final rotated = Transform.rotate(
      angle: _rotationTurns * (math.pi / 2),
      child: videoWidget,
    );

    return rotated;
  }

  // --- Audio Cover/Visualizer Area ---
  Widget _buildAudioVisualizer() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing audio record/disc mockup
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: _isPlaying ? 200 : 180,
          height: _isPlaying ? 200 : 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade900,
            image: widget.thumbnailUrl.isNotEmpty
                ? DecorationImage(image: NetworkImage(widget.thumbnailUrl), fit: BoxFit.cover)
                : null,
            boxShadow: [
              BoxShadow(
                color: MskColors.secondary.withOpacity(_isPlaying ? 0.3 : 0.1),
                blurRadius: 30,
                spreadRadius: 10,
              )
            ],
          ),
          child: widget.thumbnailUrl.isEmpty
              ? const Icon(Icons.audiotrack, size: 80, color: MskColors.secondary)
              : null,
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            widget.videoTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // --- Controls Overlay Panel ---
  Widget _buildPlayerControls() {
    final currentPos = widget.isAudioOnly
        ? _audioPosition
        : (_videoController != null && _isVideoInitialized ? _videoController!.value.position : Duration.zero);
    final totalDur = widget.isAudioOnly
        ? _audioDuration
        : (_videoController != null && _isVideoInitialized ? _videoController!.value.duration : Duration.zero);

    final double progressVal = totalDur.inMilliseconds > 0
        ? (currentPos.inMilliseconds / totalDur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title for Video mode
          if (!widget.isAudioOnly) ...[
            Text(
              widget.videoTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],

          // Slider & Times
          if (widget.isAudioOnly)
            Slider(
              value: progressVal,
              activeColor: MskColors.secondary,
              inactiveColor: Colors.white24,
              onChanged: (val) {
                final seekMs = (val * totalDur.inMilliseconds).toInt();
                if (widget.isAudioOnly) {
                  _audioPlayer?.seek(Duration(milliseconds: seekMs));
                }
              },
            ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(currentPos), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(_formatDuration(totalDur), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons: Rev, Play, Fwd, Volume
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // volume icon
              Icon(
                _volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white70,
                size: 20,
              ),
              Expanded(
                child: Slider(
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  activeColor: Colors.white70,
                  inactiveColor: Colors.white12,
                  onChanged: _changeVolume,
                ),
              ),
              
              IconButton(
                icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 28),
                onPressed: () => _seekRelative(-10),
              ),
              
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                  color: MskColors.secondary,
                  size: 54,
                ),
                onPressed: _controlsLocked ? null : _togglePlayPause,
              ),
              
              IconButton(
                icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 28),
                onPressed: () => _seekRelative(10),
              ),
              
              const SizedBox(width: 48),  // spacing offset for volume slider
            ],
          ),
          const SizedBox(height: 8),

          // Additional controls row: speed, lock, rotate, fullscreen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Speed menu
              PopupMenuButton<double>(
                initialValue: _playbackSpeed,
                tooltip: 'Playback speed',
                onSelected: (val) => _setPlaybackSpeed(val),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                  const PopupMenuItem(value: 1.0, child: Text('1.0x')),
                  const PopupMenuItem(value: 1.25, child: Text('1.25x')),
                  const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                  const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                ],
                child: Row(
                  children: [
                    const Icon(Icons.speed, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text('${_playbackSpeed}x', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),

              // Lock controls
              IconButton(
                icon: Icon(_controlsLocked ? Icons.lock : Icons.lock_open, color: Colors.white70),
                onPressed: _toggleControlsLock,
                tooltip: _controlsLocked ? 'Unlock controls' : 'Lock controls',
              ),

              // Rotate
              IconButton(
                icon: const Icon(Icons.screen_rotation, color: Colors.white70),
                onPressed: _rotateVideo,
                tooltip: 'Rotate video',
              ),

              // Fullscreen
              IconButton(
                icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white70),
                onPressed: _toggleFullscreen,
                tooltip: _isFullscreen ? 'Exit fullscreen' : 'Fullscreen',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Custom PiP Floating Panel Mock ---
  Widget _buildMiniPlayerLayout() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 220,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MskColors.secondary, width: 2),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (widget.isAudioOnly)
                      const Icon(Icons.music_video_rounded, color: Colors.white30, size: 40)
                    else if (_videoController != null && _isVideoInitialized)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: VideoPlayer(_videoController!),
                      )
                    else
                      const Icon(Icons.movie, color: Colors.white30, size: 40),
                    // Close & Restore buttons
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.aspect_ratio_rounded, color: Colors.white, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _isMiniPlayer = false;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.videoTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: MskColors.secondary, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _togglePlayPause,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
