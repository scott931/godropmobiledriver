import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onVoiceRecord;
  final VoidCallback onVoiceStop;
  final bool isRecording;
  final VoidCallback? onAttachment;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onVoiceRecord,
    required this.onVoiceStop,
    required this.isRecording,
    this.onAttachment,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  void _handleVoicePress() {
    if (widget.isRecording) {
      widget.onVoiceStop();
    } else {
      widget.onVoiceRecord();
    }
  }

  @override
  Widget build(BuildContext context) {
    final blueColor = const Color(0xFF4A90E2);

    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Microphone icon on the left
              GestureDetector(
                onTap: _handleVoicePress,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  child: Icon(
                    widget.isRecording ? Icons.mic : Icons.mic_outlined,
                    color: Colors.grey[600],
                    size: 24.sp,
                  ),
                ),
              ),

              SizedBox(width: 8.w),

              // Input field in the middle
              Expanded(
                child: Container(
                  constraints: BoxConstraints(minHeight: 48.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    decoration: InputDecoration(
                      hintText: 'Type here...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: InputBorder.none,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    cursorColor: blueColor,
                    cursorWidth: 2,
                  ),
                ),
              ),

              SizedBox(width: 8.w),

              // Attachment icon
              GestureDetector(
                onTap: widget.onAttachment,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  child: Icon(
                    Icons.attach_file,
                    color: Colors.grey[600],
                    size: 24.sp,
                  ),
                ),
              ),

              SizedBox(width: 8.w),

              // Blue circular send button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onSend,
                  borderRadius: BorderRadius.circular(24.r),
                  child: Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: blueColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22.sp,
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
}
