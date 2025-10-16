import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onVoiceRecord;
  final VoidCallback onVoiceStop;
  final bool isRecording;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onVoiceRecord,
    required this.onVoiceStop,
    required this.isRecording,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  bool _isRecording = false;

  void _handleVoicePress() {
    if (_isRecording) {
      widget.onVoiceStop();
      setState(() {
        _isRecording = false;
      });
    } else {
      widget.onVoiceRecord();
      setState(() {
        _isRecording = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        children: [
          // Attachment button
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.home_outlined,
              color: Colors.grey[600],
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          // Text input field
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      decoration: InputDecoration(
                        hintText: 'Send Message',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: Colors.grey[500],
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.black87,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => widget.onSend(),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.grey[500],
                    size: 20.sp,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Voice recording button
          GestureDetector(
            onTap: _handleVoicePress,
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : const Color(0xFF8B5CF6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
