import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../../core/models/message_model.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/storage_service.dart';

class VoiceMessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onPlay;

  const VoiceMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onPlay,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  bool _isDownloading = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  late AnimationController _animationController;
  late AudioPlayer _audioPlayer;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _audioPlayer = AudioPlayer();
    _retryCount = 0;

    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
        if (state == PlayerState.playing) {
          _animationController.repeat();
        } else {
          _animationController.stop();
        }
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        print('🎵 Audio duration detected: ${duration.inSeconds} seconds');
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Listen to completion
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
        _animationController.stop();
      }
    });
  }

  @override
  void didUpdateWidget(VoiceMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the URL changed, clear cached file and retry count
    final oldUrl =
        oldWidget.message.voiceUrl ?? oldWidget.message.attachmentUrl;
    final newUrl = widget.message.voiceUrl ?? widget.message.attachmentUrl;
    if (oldUrl != newUrl &&
        (oldUrl == null || oldUrl.isEmpty) &&
        (newUrl != null && newUrl.isNotEmpty)) {
      print('🔄 Voice message URL updated! Old: $oldUrl, New: $newUrl');
      _localFilePath = null;
      _retryCount = 0;
      // If we were downloading, retry now that URL is available
      if (_isDownloading) {
        setState(() {
          _isDownloading = false;
        });
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted && !_isPlaying) {
            _togglePlay();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _getVoiceUrl() {
    // Get voice URL from voiceUrl or attachmentUrl
    final url = widget.message.voiceUrl ?? widget.message.attachmentUrl;

    print('🔊 _getVoiceUrl called:');
    print('   message.voiceUrl: ${widget.message.voiceUrl}');
    print('   message.attachmentUrl: ${widget.message.attachmentUrl}');
    print('   Selected URL: $url');

    if (url == null || url.isEmpty) {
      print('⚠️ URL is null or empty');
      return '';
    }

    // If URL is already absolute, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      print('✅ URL is already absolute: $url');
      return url;
    }

    // If URL is relative, prepend base URL
    final baseUrl = AppConfig.baseUrl.trim();
    // Remove trailing slash from baseUrl if present
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final finalUrl = url.startsWith('/')
        ? '$cleanBaseUrl$url'
        : '$cleanBaseUrl/$url';
    print('✅ Constructed absolute URL: $finalUrl');
    return finalUrl;
  }

  Future<bool> _checkFileExists(String url) async {
    try {
      final token = StorageService.getAuthToken();
      if (token == null || token.isEmpty) return false;

      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.connectTimeout = Duration(seconds: 10);
      dio.options.receiveTimeout = Duration(seconds: 10);

      // Use HEAD request to check if file exists without downloading
      final response = await dio.head(url);
      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ File existence check failed: $e');
      return false;
    }
  }

  Future<String?> _downloadAudioFile(String url, {bool retry = false}) async {
    try {
      print(
        '📥 Downloading audio file: $url (retry: $retry, attempt: ${_retryCount + 1})',
      );

      // Get token for authentication
      final token = StorageService.getAuthToken();
      if (token == null || token.isEmpty) {
        print('⚠️ No auth token available for download');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication required. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      print('✅ Auth token found: ${token.substring(0, 10)}...');

      // Check if file exists before attempting download (only on first attempt)
      if (!retry && _retryCount == 0) {
        print('🔍 Checking if file exists on server...');
        final exists = await _checkFileExists(url);
        if (!exists) {
          print('⚠️ File does not exist yet on server');
          // File might still be processing, don't error yet
        } else {
          print('✅ File exists on server');
        }
      }

      // Create Dio instance for download with proper configuration
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Accept'] = '*/*';
      dio.options.connectTimeout = Duration(seconds: 30);
      dio.options.receiveTimeout = Duration(seconds: 30);

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final fileName =
          'voice_${widget.message.id}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${directory.path}/$fileName';

      print('📁 Saving to: $filePath');

      // Download file with progress callback
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('📥 Download progress: $progress%');
          }
        },
      );

      // Verify file was downloaded
      final file = File(filePath);
      if (!await file.exists()) {
        print('❌ Downloaded file does not exist!');
        return null;
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        print('❌ Downloaded file is empty!');
        return null;
      }

      print('✅ Audio file downloaded to: $filePath ($fileSize bytes)');
      _retryCount = 0; // Reset retry count on success
      return filePath;
    } on DioException catch (e) {
      print('❌ DioError downloading audio file:');
      print('   Type: ${e.type}');
      print('   Message: ${e.message}');
      print('   Response: ${e.response?.statusCode} - ${e.response?.data}');
      print('   Headers sent: ${e.requestOptions.headers}');

      String errorMsg = 'Failed to download audio';
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          errorMsg = 'Authentication failed. Please login again.';
        } else if (e.response!.statusCode == 403) {
          errorMsg = 'Access denied. Please check permissions.';
        } else if (e.response!.statusCode == 404) {
          _retryCount++;
          if (_retryCount < _maxRetries) {
            errorMsg =
                'File still processing ($_retryCount/$_maxRetries). Retrying in ${2 * _retryCount} seconds...';
            // Auto-retry with exponential backoff
            Future.delayed(Duration(seconds: 2 * _retryCount), () {
              if (mounted) {
                print(
                  '🔄 Auto-retrying download (attempt ${_retryCount + 1}/$_maxRetries)...',
                );
                _togglePlay();
              }
            });
          } else {
            errorMsg =
                'Audio file not found on server. The file may still be processing. Please wait and try again later.';
          }
        } else {
          errorMsg = 'Server error (${e.response!.statusCode})';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = 'Connection error. Please check your internet.';
      }

      if (mounted) {
        // Only show manual retry button if auto-retry failed or user wants to retry immediately
        final showRetry =
            e.response?.statusCode == 404 && _retryCount >= _maxRetries;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: e.response?.statusCode == 404
                ? Colors.orange
                : Colors.red,
            duration: Duration(
              seconds:
                  e.response?.statusCode == 404 && _retryCount < _maxRetries
                  ? 8
                  : 5,
            ),
            action: showRetry
                ? SnackBarAction(
                    label: 'Retry Now',
                    textColor: Colors.white,
                    onPressed: () {
                      // Reset retry count and clear cache
                      _retryCount = 0;
                      _localFilePath = null;
                      Future.delayed(Duration(milliseconds: 500), () {
                        if (mounted) {
                          _togglePlay();
                        }
                      });
                    },
                  )
                : null,
          ),
        );
      }
      return null;
    } catch (e, stackTrace) {
      print('❌ Unexpected error downloading audio file: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _togglePlay() async {
    final voiceUrl = _getVoiceUrl();

    if (voiceUrl.isEmpty) {
      print('⚠️ No voice URL available');
      print('   message.voiceUrl: ${widget.message.voiceUrl}');
      print('   message.attachmentUrl: ${widget.message.attachmentUrl}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Audio file URL not available yet. The file may still be processing. Please wait a moment and try again.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                // Trigger a refresh - you may want to add a callback for this
                Future.delayed(Duration(milliseconds: 500), () {
                  _togglePlay();
                });
              },
            ),
          ),
        );
      }
      return;
    }

    print('🔊 Voice message URL: $voiceUrl');
    print('🔊 Voice duration: ${widget.message.voiceDuration} seconds');

    try {
      if (_isPlaying) {
        // Check player state before stopping to avoid errors
        final state = _audioPlayer.state;
        if (state == PlayerState.playing || state == PlayerState.paused) {
          await _audioPlayer.stop();
        }
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      } else {
        // Stop any existing playback first
        try {
          final currentState = _audioPlayer.state;
          if (currentState == PlayerState.playing ||
              currentState == PlayerState.paused) {
            await _audioPlayer.stop();
          }
        } catch (e) {
          print('⚠️ Error stopping previous playback: $e');
        }

        // Reset position
        setState(() {
          _position = Duration.zero;
        });

        // Download and play audio file with authentication
        if (_localFilePath == null || !await File(_localFilePath!).exists()) {
          setState(() {
            _isDownloading = true;
            _retryCount = 0; // Reset retry count when starting new download
          });

          // Download file with authentication
          final localPath = await _downloadAudioFile(
            voiceUrl,
            retry: _retryCount > 0,
          );

          if (localPath == null || !await File(localPath).exists()) {
            if (mounted) {
              setState(() {
                _isDownloading = false;
              });
              // Error message and retry logic already handled in _downloadAudioFile
            }
            return;
          }

          setState(() {
            _localFilePath = localPath;
            _isDownloading = false;
            _retryCount = 0; // Reset on success
          });
        }

        // Play from local file - duration will be automatically detected
        print('▶️ Playing audio from local file: $_localFilePath');
        await _audioPlayer.play(DeviceFileSource(_localFilePath!));
        // Duration will be automatically detected via onDurationChanged listener
      }
      widget.onPlay?.call();
    } catch (e, stackTrace) {
      print('❌ Error playing voice message: $e');
      print('Stack trace: $stackTrace');
      print('URL attempted: $voiceUrl');
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to play voice message. Please check your connection.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDurationFromSeconds(int seconds) {
    if (seconds <= 0) return '00:00';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getDisplayDuration() {
    // If playing and we have duration, show position / total
    if (_isPlaying && _duration.inSeconds > 0) {
      return '${_formatDuration(_position)} / ${_formatDuration(_duration)}';
    }

    // If we have detected duration from audio file, show it
    if (_duration.inSeconds > 0) {
      return _formatDuration(_duration);
    }

    // If message has duration, show it (this is the main case for sent messages)
    if (widget.message.voiceDuration != null &&
        widget.message.voiceDuration! > 0) {
      return _formatDurationFromSeconds(widget.message.voiceDuration!);
    }

    // Default fallback - show as loading or unknown
    return '00:00';
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = _formatTime(widget.message.timestamp);

    if (widget.isMe) {
      // Outgoing voice message (right-aligned, blue bubble)
      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // "You" label
                  Padding(
                    padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
                    child: Text(
                      'You',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  // Voice message bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                      minWidth: 200.w,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2), // Blue color
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        // Play button
                        GestureDetector(
                          onTap: _isDownloading ? null : _togglePlay,
                          child: Container(
                            width: 32.w,
                            height: 32.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: _isDownloading
                                ? SizedBox(
                                    width: 16.w,
                                    height: 16.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Waveform visualization
                              SizedBox(
                                height: 20.h,
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      painter: WaveformPainter(
                                        isPlaying: _isPlaying,
                                        animationValue:
                                            _animationController.value,
                                      ),
                                      size: Size.infinite,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                _getDisplayDuration(),
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Timestamp
                  Padding(
                    padding: EdgeInsets.only(right: 8.w, top: 4.h),
                    child: Text(
                      timestamp,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Incoming voice message (left-aligned, grey bubble)
      return Container(
        margin: EdgeInsets.only(bottom: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile picture
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child:
                  widget.message.displayAvatar != null &&
                      widget.message.displayAvatar!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.message.displayAvatar!,
                        width: 32.w,
                        height: 32.w,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildInitialsAvatar(
                            widget.message.displaySenderName,
                          );
                        },
                      ),
                    )
                  : _buildInitialsAvatar(widget.message.displaySenderName),
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender name
                  Padding(
                    padding: EdgeInsets.only(left: 8.w, bottom: 4.h),
                    child: Text(
                      widget.message.displaySenderName.isNotEmpty
                          ? widget.message.displaySenderName
                          : 'Unknown',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Voice message bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                      minWidth: 200.w,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        // Play button
                        GestureDetector(
                          onTap: _isDownloading ? null : _togglePlay,
                          child: Container(
                            width: 32.w,
                            height: 32.w,
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                            child: _isDownloading
                                ? SizedBox(
                                    width: 16.w,
                                    height: 16.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Waveform visualization
                              SizedBox(
                                height: 20.h,
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      painter: WaveformPainter(
                                        isPlaying: _isPlaying,
                                        animationValue:
                                            _animationController.value,
                                      ),
                                      size: Size.infinite,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                _getDisplayDuration(),
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Timestamp
                  Padding(
                    padding: EdgeInsets.only(left: 8.w, top: 4.h),
                    child: Text(
                      timestamp,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInitialsAvatar(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final bool isPlaying;
  final double animationValue;

  WaveformPainter({required this.isPlaying, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final barWidth = 3.0;
    final spacing = 2.0;
    final totalBars = (size.width / (barWidth + spacing)).floor();
    final activeWidth = isPlaying
        ? size.width * animationValue
        : size.width * 0.3;

    for (int i = 0; i < totalBars; i++) {
      final x = i * (barWidth + spacing);
      final height = (i % 3 == 0) ? size.height * 0.6 : size.height * 0.3;

      if (x < activeWidth) {
        canvas.drawLine(
          Offset(x, centerY - height / 2),
          Offset(x, centerY + height / 2),
          activePaint,
        );
      } else {
        canvas.drawLine(
          Offset(x, centerY - height / 2),
          Offset(x, centerY + height / 2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
