import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/message_model.dart';
import '../../../core/utils/avatar_color_utils.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onDelete,
  });

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = _formatTime(message.timestamp);

    if (isMe) {
      // Outgoing message (right-aligned, blue bubble) with swipe-to-delete
      final messageContent = Container(
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
                  // Message bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2), // Blue color
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      message.content,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.white,
                        height: 1.3,
                      ),
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

      if (onDelete != null) {
        return Dismissible(
          key: Key('message_${message.id}'),
          direction: DismissDirection.endToStart, // Swipe left to delete
          background: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 28.sp,
            ),
          ),
          confirmDismiss: (direction) async {
            // Show confirmation dialog before deleting
            final shouldDelete = await _showDeleteDialog(context);
            return shouldDelete ?? false;
          },
          onDismissed: (direction) {
            // This will be called after confirmDismiss returns true
            onDelete?.call();
          },
          child: messageContent,
        );
      } else {
        return messageContent;
      }
    } else {
      // Incoming message (left-aligned, grey bubble)
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
              child: message.displayAvatar != null && message.displayAvatar!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        message.displayAvatar!,
                        width: 32.w,
                        height: 32.w,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildInitialsAvatar(message.displaySenderName);
                        },
                      ),
                    )
                  : _buildInitialsAvatar(message.displaySenderName),
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
                      message.displaySenderName.isNotEmpty
                          ? message.displaySenderName
                          : 'Unknown',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Message bubble
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      message.content,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.black,
                        height: 1.3,
                      ),
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

  Future<bool?> _showDeleteDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Delete Message',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this message?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInitialsAvatar(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final backgroundColor = AvatarColorUtils.getColorForName(name);
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
