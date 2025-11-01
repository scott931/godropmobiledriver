import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/message_model.dart';
import '../../../core/config/app_config.dart';

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
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getVoiceUrl() {
    // Get voice URL from voiceUrl or attachmentUrl
    final url = widget.message.voiceUrl ?? widget.message.attachmentUrl;
    if (url == null || url.isEmpty) return '';

    // If URL is already absolute, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // If URL is relative, prepend base URL
    final baseUrl = AppConfig.baseUrl;
    if (url.startsWith('/')) {
      return '$baseUrl$url';
    }
    return '$baseUrl/$url';
  }

  void _togglePlay() {
    final voiceUrl = _getVoiceUrl();

    // TODO: Implement audio playback using an audio player package (e.g., audioplayers or just_audio)
    // For now, just toggle the UI state
    print('🔊 Voice message URL: $voiceUrl');
    print('🔊 Voice duration: ${widget.message.voiceDuration} seconds');

    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _animationController.repeat();
      // TODO: Start audio playback here
      // Example with audioplayers:
      // AudioPlayer().play(UrlSource(voiceUrl));
    } else {
      _animationController.stop();
      // TODO: Stop audio playback here
      // Example with audioplayers:
      // AudioPlayer().stop();
    }

    widget.onPlay?.call();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: widget.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isMe) ...[
            CircleAvatar(
              radius: 16.r,
              backgroundImage: widget.message.displayAvatar != null
                  ? NetworkImage(widget.message.displayAvatar!)
                  : null,
              child: widget.message.displayAvatar == null
                  ? Text(
                      widget.message.displaySenderName.isNotEmpty
                          ? widget.message.displaySenderName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
                minWidth: 200.w,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: widget.isMe ? const Color(0xFF8B5CF6) : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.r),
                  topRight: Radius.circular(18.r),
                  bottomLeft: widget.isMe
                      ? Radius.circular(18.r)
                      : Radius.circular(4.r),
                  bottomRight: widget.isMe
                      ? Radius.circular(4.r)
                      : Radius.circular(18.r),
                ),
              ),
              child: Row(
                children: [
                  if (!widget.isMe) ...[
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ],
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
                                  animationValue: _animationController.value,
                                ),
                                size: Size.infinite,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _formatDuration(widget.message.voiceDuration ?? 0),
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: widget.isMe
                                ? Colors.white70
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isMe) ...[
                    SizedBox(width: 12.w),
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (widget.isMe) ...[
            SizedBox(width: 8.w),
            CircleAvatar(
              radius: 16.r,
              backgroundColor: const Color(0xFF8B5CF6),
              child: Text(
                'Y',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
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
